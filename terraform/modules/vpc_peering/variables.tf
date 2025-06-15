variable "project_name" {
  description = "Project name"
  type        = string
}

variable "shared_vpc_self_link" {
  description = "Self link of the shared VPC"
  type        = string
}

variable "environment_vpcs" {
  description = "Map of environment names to their VPC self links"
  type        = map(string)
  default = {
    dev  = ""
    test = ""
    prod = ""
  }
}

variable "environment_networks" {
  description = "Map of environment names to their network CIDR blocks"
  type        = map(string)
  default = {
    dev  = "10.0.0.0/16"
    test = "10.1.0.0/16"
    prod = "10.2.0.0/16"
  }
}
