terraform {
  required_providers {
    bigip = {
      source = "F5Networks/bigip"
      version = "1.22.2"
    }
  }
}

resource "bigip_as3" "as3" {
  tenant_name= var.partition
  as3_json = templatefile("${path.module}/as3.tpl", {
    name            = var.name
    virtualIP       = var.virtualIP
    virtualPort     = var.virtualPort
    serverAddresses = var.serverAddresses
    servicePort     = var.servicePort
  })
}

output "as3" {
  value = bigip_as3.as3
}

