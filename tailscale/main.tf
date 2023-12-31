data "azurerm_resource_group" "this" {
  name = "${var.deployment_prefix}"
}



resource "azurerm_virtual_network" "this" {
  name                = "${var.deployment_prefix}-vnet"
  address_space       = ["${var.network_cidr_prefix}.0/24"]
  location            = data.azurerm_resource_group.this.location
  resource_group_name = data.azurerm_resource_group.this.name
}

resource "azurerm_subnet" "this" {
  name                 = "subnet"
  resource_group_name  = data.azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = ["${var.network_cidr_prefix}.0/25"]
}


resource "azurerm_subnet" "this2" {
  name                 = "subnet2"
  resource_group_name  = data.azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = ["${var.network_cidr_prefix}.128/25"]
}


resource "azurerm_network_security_group" "this" {
  name                = "${var.deployment_prefix}-nsg"
  location            = data.azurerm_resource_group.this.location
  resource_group_name = data.azurerm_resource_group.this.name
}

# associate nsg with subnet

resource "azurerm_subnet_network_security_group_association" "this" {
  subnet_id                 = azurerm_subnet.this.id
  network_security_group_id = azurerm_network_security_group.this.id
}

resource "azurerm_subnet_network_security_group_association" "this2" {
  subnet_id                 = azurerm_subnet.this2.id
  network_security_group_id = azurerm_network_security_group.this.id
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
resource "azurerm_network_security_rule" "https" {
  name                        = "https"
  priority                    = 1003
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
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

# route table 

resource "azurerm_route_table" "this" {
  name                = "${var.deployment_prefix}-rt"
  location            = data.azurerm_resource_group.this.location
  resource_group_name = data.azurerm_resource_group.this.name
}

# route table association

resource "azurerm_subnet_route_table_association" "this" {
  subnet_id      = azurerm_subnet.this2.id
  route_table_id = azurerm_route_table.this.id
}

# route table route

resource "azurerm_route" "this" {
  name                = "tailscale"
  resource_group_name = data.azurerm_resource_group.this.name
  route_table_name    = azurerm_route_table.this.name
  address_prefix      = "192.168.1.0/24"
  next_hop_type       = "VirtualAppliance"
  next_hop_in_ip_address = azurerm_linux_virtual_machine.this.private_ip_address
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
  priority            = var.vm_priority
  eviction_policy     = var.vm_priority == "Spot" ? "Delete" : null

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
    sku       = "12-arm64"
    version   = "latest"
  }
  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.this.primary_blob_endpoint

  }
}
data "azurerm_resource_group" "dns" {
  name = "DNS-Zones"
}

data "azurerm_public_ip" "this" {
  name                = "${var.deployment_prefix}-pip"
  resource_group_name = data.azurerm_resource_group.this.name
  depends_on          = [azurerm_linux_virtual_machine.this]
}

data "azurerm_dns_zone" "this" {
  name                = "scare.io"
  resource_group_name = data.azurerm_resource_group.dns.name
}


# create dns record
resource "azurerm_dns_a_record" "this" {
  name                = "tailscale"
  zone_name           = data.azurerm_dns_zone.this.name
  resource_group_name = data.azurerm_resource_group.dns.name
  ttl                 = 300
  records             = [data.azurerm_public_ip.this.ip_address]
}


data "template_file" "this" {
  template = file("../data/cloudinit.yml")
  vars = {
    config_json = base64encode(data.template_file.userdata.rendered)
    get_tailscale_key_py = base64encode(data.template_file.get_tailscale_key_py.rendered)
    init_sh = base64encode(data.template_file.init_sh.rendered)
    authorise_routes_py = base64encode(data.template_file.authorise_routes_py.rendered)
    eviction_check_sh = base64encode(data.template_file.eviction_check_sh.rendered)
    eviction_check_service = base64encode(data.template_file.eviction_check_service.rendered)
    eviction_check_timer = base64encode(data.template_file.eviction_check_timer.rendered)

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

data "template_file" "userdata" {
  template = file("../data/userdata.json.tpl")
  vars = {
    TAILSCALE_CLIENT_ID = var.TAILSCALE_CLIENT_ID
    TAILSCALE_CLIENT_SECRET = var.TAILSCALE_CLIENT_SECRET
  }
}

# ../data/get-tailscale-key.py
data "template_file" "get_tailscale_key_py" {
  template = file("../data/get-tailscale-key.py")
}

# ../data/init.sh
data "template_file" "init_sh" {
  template = file("../data/init.sh")
  vars = {
    network_cidr_prefix = var.network_cidr_prefix
  }
}

# ../data/authorise_routes.py

data "template_file" "authorise_routes_py" {
  template = file("../data/authorise_routes.py")
}

#../data/eviction_check.sh
data "template_file" "eviction_check_sh" {
  template = file("../data/eviction-check.sh")
}

#../data/eviction-check.service
data "template_file" "eviction_check_service" {
  template = file("../data/eviction-check.service")
}

#../data/eviction-check.timer
data "template_file" "eviction_check_timer" {
  template = file("../data/eviction-check.timer")
}


