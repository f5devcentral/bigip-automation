terraform {
  required_providers {
    bigip = {
      source = "F5Networks/bigip"
      version = "1.22.2"
    }
  }
}

provider "bigip" {
    address = "10.1.10.215"
    username = "admin"
    password = "Kostas1234"
    alias=  "dmz"
}
/*
# How to add multiple providers
provider "bigip" {
    address = "10.1.20.112"
    username = "admin"
    password = "passwordXYZ"
    alias=  "azure"
}
*/