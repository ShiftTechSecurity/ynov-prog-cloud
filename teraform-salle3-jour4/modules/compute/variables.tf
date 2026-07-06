variable "name_prefix" {
  description = "Resource name prefix."
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type."
  type        = string
}

variable "kms_key_arn" {
  description = "KMS key ARN for encrypted volumes."
  type        = string
}

variable "instance_profile_name" {
  description = "IAM instance profile attached to EC2 instances."
  type        = string
}

variable "tier_config" {
  description = "Configuration for each application tier."
  type = map(object({
    role                = string
    subnet_id           = string
    security_group_id   = string
    private_ip          = string
    associate_public_ip = bool
    data_volume_size    = number
    user_data           = string
  }))
}

variable "tags" {
  description = "Common tags."
  type        = map(string)
}
