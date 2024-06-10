
output "remote_vnet" {
  value = data.terraform_remote_state.devbox.outputs.subnet2_id
}

# public ip 

resource "azurerm_public_ip" "this" {
  name                = "${var.deployment_prefix}-pip"
  location            = data.terraform_remote_state.devbox.outputs.location
  resource_group_name = data.terraform_remote_state.devbox.outputs.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
}


resource "azurerm_network_interface" "this" {
  name                = "${var.deployment_prefix}-nic"
  location            = data.terraform_remote_state.devbox.outputs.location
  resource_group_name = data.terraform_remote_state.devbox.outputs.resource_group_name

  ip_configuration {
    name                          = "${var.deployment_prefix}-nic-ip"
    subnet_id                     = data.terraform_remote_state.devbox.outputs.subnet2_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.this.id
  }
}



resource "azurerm_linux_virtual_machine" "this" {
  name                = "devbox"
  computer_name       = "devbox"
  location            = data.terraform_remote_state.devbox.outputs.location
  resource_group_name = data.terraform_remote_state.devbox.outputs.resource_group_name
  size                = "Standard_D8d_v4"
  admin_username      = "debian"
  custom_data         = data.template_cloudinit_config.this.rendered
  priority        = var.vm_priority
  eviction_policy = var.vm_priority == "Spot" ? "Deallocate" : null
  zone = 1

  network_interface_ids = [
    azurerm_network_interface.this.id,
  ]
  admin_ssh_key {
    username   = var.vm_username
    public_key = var.ssh_public_key
  }
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_ZRS"
  }
  source_image_reference {
    publisher = "debian"
    offer     = "debian-12"
    sku       = "12-gen2"
    version   = "latest"
  }
  boot_diagnostics {
    storage_account_uri = data.terraform_remote_state.devbox.outputs.primary_blob_endpoint

  }
}

data "azurerm_managed_disk" "this" {
  name                = "devbox"
  resource_group_name = "storage"
}

resource "azurerm_virtual_machine_data_disk_attachment" "this" {
  managed_disk_id    = data.azurerm_managed_disk.this.id
  virtual_machine_id = azurerm_linux_virtual_machine.this.id
  lun                = 0
  caching            = "None"
}


data "azurerm_resource_group" "dns" {
  name = "DNS-Zones"
}

data "azurerm_public_ip" "this" {
  name                = "${var.deployment_prefix}-pip"
  resource_group_name = data.terraform_remote_state.devbox.outputs.resource_group_name
  depends_on          = [azurerm_linux_virtual_machine.this]
}

data "azurerm_dns_zone" "this" {
  name                = "scare.io"
  resource_group_name = data.azurerm_resource_group.dns.name
}


# create dns record
resource "azurerm_dns_a_record" "this" {
  name                = "devbox"
  zone_name           = data.azurerm_dns_zone.this.name
  resource_group_name = data.azurerm_resource_group.dns.name
  ttl                 = 300
  records             = [data.azurerm_public_ip.this.ip_address]
}



data "template_file" "this" {
  template = file("cloudinit.yml")
  vars = {

  }

}

data "template_cloudinit_config" "this" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    content      = data.template_file.this.rendered
  }
}
