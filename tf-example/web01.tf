resource "bigip_as3" "web01" {
  as3_json = file("web01.json")
  tenant_name = "example"
  provider = bigip.dmz
}