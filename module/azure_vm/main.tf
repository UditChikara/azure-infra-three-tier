
data "azurerm_subnet" "subnet_data" {
  for_each = var.vm
  name                 = each.value.subnet_name
  virtual_network_name = each.value.virtual_network_name
  resource_group_name  = each.value.resource_group_name
}

resource "azurerm_network_security_group" "nsg" {
  for_each = var.vm

  name                = each.value.nsg_name
  location            = each.value.location
  resource_group_name = each.value.resource_group_name

  dynamic "security_rule" {
    for_each = each.value.ports

    content {
      name                       = "allow-${security_rule.value}"
      priority                   = 100 + security_rule.key
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"

      source_port_range          = "*"
      destination_port_range     = tostring(security_rule.value)

      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }
  }

  tags = {
    environment = "Production"
  }
}

resource "azurerm_network_interface_security_group_association" "nss_assoc" {
  for_each = var.vm
  network_interface_id      = azurerm_network_interface.nics[each.key].id
  network_security_group_id = azurerm_network_security_group.nsg[each.key].id
}

resource "azurerm_network_interface" "nics" {
  for_each = var.vm
  name                = each.value.nic_name
  location            = each.value.location
  resource_group_name = each.value.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = data.azurerm_subnet.subnet_data[each.key].id
    public_ip_address_id          = azurerm_public_ip.public_ips[each.key].id       
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_public_ip" "public_ips" {
  for_each = var.vm
  name                = each.value.public_ip_name
  resource_group_name = each.value.resource_group_name
  location            = each.value.location
  allocation_method   = each.value.allocation_method

  
}
resource "azurerm_linux_virtual_machine" "vms" {
  for_each = var.vm
  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  location            = each.value.location
  size                = each.value.size
  admin_username      = each.value.admin_username
  network_interface_ids = [
    azurerm_network_interface.nics[each.key].id,
  ]
  disable_password_authentication = false
  admin_password = each.value.admin_password
#   admin_ssh_key {
#     username   = "adminuser"
#     public_key = file("~/.ssh/id_rsa.pub")
#   }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
 }
}