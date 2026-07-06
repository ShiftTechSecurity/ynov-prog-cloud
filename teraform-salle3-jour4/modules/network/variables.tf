variable "name_prefix" {
  description = "Resource name prefix."
  type        = string
}

variable "availability_zone" {
  description = "Availability zone."
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR."
  type        = string
}

variable "public_subnet_cidr" {
  description = "Public subnet CIDR."
  type        = string
}

variable "app_subnet_cidr" {
  description = "Application subnet CIDR."
  type        = string
}

variable "data_subnet_cidr" {
  description = "Data subnet CIDR."
  type        = string
}

variable "enable_private_nat" {
  description = "Create a NAT Gateway for private subnet package installation."
  type        = bool
}

variable "tags" {
  description = "Common tags."
  type        = map(string)
}
