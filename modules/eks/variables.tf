##### Esto no se usa, se está usando un modulo ya creado para EKS, pero lo dejo aquí como referencia #####

variable "cluster_name" { type = string }
variable "cluster_version" {
  type    = string
  default = "1.30"
}

variable "region" { type = string }

variable "vpc_id"         { type = string }
variable "private_subnet_ids" { type = list(string) }
variable "public_subnet_ids"  { type = list(string) }

variable "endpoint_public_access" {
  type    = bool
  default = true
}
variable "endpoint_private_access" {
  type    = bool
  default = false
}
variable "public_access_cidrs" {
  type    = list(string)
  default = ["0.0.0.0/0"] # en dev; luego restringimos a tu IP
}

# Node group (barato)
variable "ng_name"         { 
    type = string  
    default = "dev-ng" 
}
variable "instance_types"  { 
    type = list(string) 
    default = ["t3.small"] 
}
variable "capacity_type"   { 
    type = string 
    default = "SPOT" 
} # "ON_DEMAND" o "SPOT"
variable "desired_size"    { 
    type = number 
    default = 1 
}
variable "min_size"        { 
    type = number 
    default = 0 
}
variable "max_size"        { 
    type = number 
    default = 2 
}
variable "disk_size_gb"    { 
    type = number 
    default = 20 
}

variable "tags" {
  type    = map(string)
  default = {}
}
