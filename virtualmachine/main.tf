provider "azurerm" {
  # whilst the `version` attribute is optional, we recommend pinning to a given version of the Provider
  version = "=2.0.0"
  features {}
}

resource "azurerm_resource_group" "artigo-linkedin" {
  name     = "artigo-linkedin"
  location = "East US"
}

resource "azurerm_virtual_network" "artigo-linkedin" {
  name                = "artigo-linkedin-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.artigo-linkedin.location
  resource_group_name = azurerm_resource_group.artigo-linkedin.name
}

resource "azurerm_subnet" "artigo-linkedin" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.artigo-linkedin.name
  virtual_network_name = azurerm_virtual_network.artigo-linkedin.name
  address_prefix       = "10.0.2.0/24"
}

resource "azurerm_network_interface" "artigo-linkedin" {
  name                = "artigo-linkedin-nic"
  location            = azurerm_resource_group.artigo-linkedin.location
  resource_group_name = azurerm_resource_group.artigo-linkedin.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.artigo-linkedin.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "artigo-linkedin" {
  name                = "artigo-linkedin-machine"
  resource_group_name = azurerm_resource_group.artigo-linkedin.name
  location            = azurerm_resource_group.artigo-linkedin.location
  size                = "Standard_F2"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.artigo-linkedin.id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
}