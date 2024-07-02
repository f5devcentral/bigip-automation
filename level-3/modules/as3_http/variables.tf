variable partition	{
  description = "Partition that the AS3 will be deployed to"
  type        = string
}
variable name	{
  description = "Name of the Virtual Server"
  type        = string
}
variable virtualIP	{
  description = "IP for Virtual Server"
  type        = string
}
variable virtualPort  {
  description = "Port for Virtual Server"
  type        = number  
  default     = 0
}
variable serverAddresses  {
  description = "List of IPs for Pool Members"
  type        = list(string)
}
variable servicePort  {
  description = "Port of the Pool Members"
  type        = number
}
