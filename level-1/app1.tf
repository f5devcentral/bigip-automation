module "app1" {
    source              = "./modules/as3_http"
    name                = "app1"
    virtualIP           = "10.1.120.82"
    serverAddresses     = ["10.1.20.10", "10.1.20.11"]
    servicePort         = 80
    partition           = "uat1"
    providers = {
      bigip = bigip.dmz
    }    
}