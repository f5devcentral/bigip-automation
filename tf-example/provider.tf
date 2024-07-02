terraform {
  required_providers {
    bigip = {
      source = "F5Networks/bigip"
      version = "1.22.2"
    }
  }
}

provider "bigip" {
    address = "10.1.1.5"
    username = "admin"
    password = "Ingresslab123"
    alias=  "dmz"
}
