variable "name_prefix" {
  description = "Resource name prefix."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID."
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR used for internal DNS egress."
  type        = string
}

variable "admin_cidr" {
  description = "CIDR allowed to administer the presentation tier."
  type        = string
}

variable "app_port" {
  description = "Application port."
  type        = number
}

variable "db_port" {
  description = "Database port."
  type        = number
}

variable "tags" {
  description = "Common tags."
  type        = map(string)
}
