variable "aws_region" {
  description = "AWS region."
  type        = string
  default     = "eu-west-1"
}

variable "availability_zone" {
  description = "Main availability zone used by this classroom architecture."
  type        = string
  default     = "eu-west-1a"
}

variable "name_prefix" {
  description = "Prefix used in AWS resource names."
  type        = string
  default     = "prog-cloud-salle3"
}

variable "environment" {
  description = "Deployment environment."
  type        = string
  default     = "dev"
}

variable "prenom" {
  description = "Student or team display identifier used in tags and documentation."
  type        = string
  default     = "RTT"
}

variable "resource_suffix" {
  description = "Stable technical suffix used in AWS resource names. Change it only after destroying the existing stack."
  type        = string
  default     = "rtt"

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,30}[a-z0-9]$", var.resource_suffix))
    error_message = "resource_suffix must be 3-32 lowercase letters, numbers or hyphens, and must start/end with a letter or number."
  }
}

variable "project_owner" {
  description = "Owner tag for FinOps and traceability."
  type        = string
  default     = "operation-nordcloud"
}

variable "admin_cidr" {
  description = "CIDR allowed to reach SSH on the presentation tier."
  type        = string

  validation {
    condition     = can(cidrhost(var.admin_cidr, 0))
    error_message = "admin_cidr must be a valid CIDR block, for example 203.0.113.10/32."
  }
}

variable "vpc_cidr" {
  description = "CIDR block for the NordCloud VPC."
  type        = string
  default     = "172.20.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public presentation subnet."
  type        = string
  default     = "172.20.10.0/24"
}

variable "app_subnet_cidr" {
  description = "CIDR block for the private application subnet."
  type        = string
  default     = "172.20.20.0/24"
}

variable "data_subnet_cidr" {
  description = "CIDR block for the private data subnet."
  type        = string
  default     = "172.20.30.0/24"
}

variable "instance_type" {
  description = "EC2 instance type used for the 3 tiers."
  type        = string
  default     = "t3a.micro"
}

variable "app_port" {
  description = "Application tier port."
  type        = number
  default     = 8080

  validation {
    condition     = var.app_port > 0 && var.app_port < 65536
    error_message = "app_port must be between 1 and 65535."
  }
}

variable "db_port" {
  description = "Database tier port."
  type        = number
  default     = 5432

  validation {
    condition     = var.db_port > 0 && var.db_port < 65536
    error_message = "db_port must be between 1 and 65535."
  }
}

variable "db_app_password" {
  description = "Password used by the Python API to connect to PostgreSQL. Provide it with TF_VAR_db_app_password or the DB_APP_PASSWORD GitHub secret."
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.db_app_password) >= 16 && !can(regex("[\r\n]", var.db_app_password))
    error_message = "db_app_password must be at least 16 characters and must not contain line breaks."
  }
}

variable "encrypted_data_volume_size_gb" {
  description = "Size of encrypted data volumes attached to sensitive tiers."
  type        = number
  default     = 20

  validation {
    condition     = var.encrypted_data_volume_size_gb >= 8
    error_message = "encrypted_data_volume_size_gb must be at least 8."
  }
}

variable "enable_private_nat" {
  description = "Create a NAT Gateway so private app/db tiers can install packages during bootstrap."
  type        = bool
  default     = true
}

variable "enable_nonprod_schedule" {
  description = "Create EventBridge schedules to stop/start non-production EC2 instances."
  type        = bool
  default     = false
}

variable "stop_schedule_expression" {
  description = "EventBridge Scheduler cron expression used to stop non-production instances."
  type        = string
  default     = "cron(0 19 ? * MON-FRI *)"
}

variable "start_schedule_expression" {
  description = "EventBridge Scheduler cron expression used to start non-production instances."
  type        = string
  default     = "cron(0 8 ? * MON-FRI *)"
}

variable "schedule_timezone" {
  description = "Timezone used by EventBridge schedules."
  type        = string
  default     = "Europe/Paris"
}
