module "app1" {
    source              = "./modules/as3_http"
    name                = "app1"
    virtualIP           = "10.1.120.41"
    serverAddresses     = ["10.1.20.21"]
    servicePort         = 30880
    partition           = "prod"
    providers = {
      bigip = bigip.dmz
    }    
}