provider "azurerm" {
  features {

    virtual_machine {
      delete_os_disk_on_deletion     = true
    }
  }
}

