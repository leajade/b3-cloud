terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=3.0.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg-b3-vm1" {
  name     = "b3-vm1"
  location = "eastus"
}

resource "azurerm_virtual_network" "vn-b3-vm1" {
  name                = "b3-vm1"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg-b3-vm1.location
  resource_group_name = azurerm_resource_group.rg-b3-vm1.name
}

resource "azurerm_subnet" "s-b3-vm1" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.rg-b3-vm1.name
  virtual_network_name = azurerm_virtual_network.vn-b3-vm1.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_public_ip" "ip-public" {
  name                    = "test-pip"
  location                = azurerm_resource_group.rg-b3-vm1.location
  resource_group_name     = azurerm_resource_group.rg-b3-vm1.name
  allocation_method       = "Dynamic"
  idle_timeout_in_minutes = 30

  tags = {
    environment = "test"
  }
}

resource "azurerm_network_interface" "nic-b3-vm1" {
  name                = "example-nic"
  location            = azurerm_resource_group.rg-b3-vm1.location
  resource_group_name = azurerm_resource_group.rg-b3-vm1.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.s-b3-vm1.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface" "nic-b3-vm2" {
  name                = "example-nic-vm2"
  location            = azurerm_resource_group.rg-b3-vm1.location
  resource_group_name = azurerm_resource_group.rg-b3-vm1.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.s-b3-vm1.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.ip-public.id
  }
}

resource "azurerm_linux_virtual_machine" "vm-b3-vm1" {
  name                = "node1"
  resource_group_name = azurerm_resource_group.rg-b3-vm1.name
  location            = azurerm_resource_group.rg-b3-vm1.location
  size                = "Standard_B1s"
  admin_username      = "leaduvigneau"
  network_interface_ids = [
    azurerm_network_interface.nic-b3-vm1.id,
  ]

  admin_ssh_key {
    username   = "leaduvigneau"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}

resource "azurerm_linux_virtual_machine" "vm-b3-vm2" {
  name                = "node2"
  resource_group_name = azurerm_resource_group.rg-b3-vm1.name
  location            = azurerm_resource_group.rg-b3-vm1.location
  size                = "Standard_B1s"
  admin_username      = "leaduvigneau"
  network_interface_ids = [
    azurerm_network_interface.nic-b3-vm2.id,
  ]

  admin_ssh_key {
    username   = "leaduvigneau"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "OpenLogic"
    offer     = "CentOS"
    sku       = "7.5"
    version   = "latest"
  }
}

