data "azurerm_resource_group" "this" {
  name = "${var.deployment_prefix}"
}

resource "azurerm_virtual_network" "this" {
  name                = "${var.deployment_prefix}-vnet"
  address_space       = ["192.168.11.0/24"]
  location            = data.azurerm_resource_group.this.location
  resource_group_name = data.azurerm_resource_group.this.name
}

resource "azurerm_subnet" "this" {
  name                 = "subnet"
  resource_group_name  = data.azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = ["192.168.11.0/25"]
}


resource "azurerm_subnet" "this2" {
  name                 = "subnet2"
  resource_group_name  = data.azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = ["192.168.11.128/25"]
}


resource "azurerm_network_security_group" "this" {
  name                = "${var.deployment_prefix}-nsg"
  location            = data.azurerm_resource_group.this.location
  resource_group_name = data.azurerm_resource_group.this.name
}

# allow ssh 
resource "azurerm_network_security_rule" "ssh" {
  name                        = "ssh"
  priority                    = 1001
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "185.214.222.183"
  destination_address_prefix  = "*"
  resource_group_name         = data.azurerm_resource_group.this.name
  network_security_group_name = azurerm_network_security_group.this.name
}
#allow nntp 
resource "azurerm_network_security_rule" "nntp" {
  name                        = "nntp"
  priority                    = 1002
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "119"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = data.azurerm_resource_group.this.name
  network_security_group_name = azurerm_network_security_group.this.name
}

# create nic

resource "azurerm_network_interface" "this" {
  name                = "${var.deployment_prefix}-nic"
  location            = data.azurerm_resource_group.this.location
  resource_group_name = data.azurerm_resource_group.this.name

  ip_configuration {
    name                          = "${var.deployment_prefix}-nic-ip"
    subnet_id                     = azurerm_subnet.this.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.this.id
  }
}

# create public ip

resource "azurerm_public_ip" "this" {
  name                = "${var.deployment_prefix}-pip"
  location            = data.azurerm_resource_group.this.location
  resource_group_name = data.azurerm_resource_group.this.name
  allocation_method   = "Dynamic"
}

# random id for storage account

resource "random_id" "this" {
  byte_length = 2
}

# diagnostics storage account

resource "azurerm_storage_account" "this" {
  name                     = replace(substr(lower("${var.deployment_prefix}${random_id.this.hex}"), 0, 23), "-", "")
  resource_group_name      = data.azurerm_resource_group.this.name
  location                 = data.azurerm_resource_group.this.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}



resource "azurerm_linux_virtual_machine" "this" {
  name                = var.vm_name
  computer_name       = var.vm_name
  resource_group_name = data.azurerm_resource_group.this.name
  location            = data.azurerm_resource_group.this.location
  size                = var.vm_size_map[var.vm_tshirt_size]
  admin_username      = var.vm_username
  custom_data         = data.template_cloudinit_config.this.rendered
  priority            = "Spot"
  eviction_policy     = "Deallocate"

  network_interface_ids = [
    azurerm_network_interface.this.id,
  ]
  admin_ssh_key {
    username   = var.vm_username
    public_key = var.ssh_public_key
  }
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = "debian"
    offer     = "debian-12"
    sku       = "12-gen2"
    version   = "latest"
  }
  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.this.primary_blob_endpoint

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

data "template_file" "this" {
  template = file("data/cloudinit.yml")
  vars = {
    config_json = base64encode(data.template_file.userdata.rendered)
  }

}