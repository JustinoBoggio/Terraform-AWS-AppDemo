variable "name" { type = string }
variable "cidr_block" { type = string }
variable "azs" { type = list(string) }               # p.ej. ["us-east-1a","us-east-1b"]
variable "public_subnets" { type = list(string) }     # p.ej. ["10.0.1.0/24","10.0.2.0/24"]
variable "private_subnets" { type = list(string) }    # p.ej. ["10.0.11.0/24","10.0.12.0/24"]

variable "enable_nat_gateway" {
  type    = bool
  default = true
}
variable "single_nat_gateway" { 
  type = bool  
  default = true 
}   # 1 NAT para todo dev (barato)

variable "tags" {
  type    = map(string)
  default = {}
}
