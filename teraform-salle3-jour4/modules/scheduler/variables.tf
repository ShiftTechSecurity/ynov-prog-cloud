variable "enable_schedule" {
  description = "Whether stop/start schedules are created."
  type        = bool
}

variable "name_prefix" {
  description = "Resource name prefix."
  type        = string
}

variable "instance_ids" {
  description = "EC2 instance IDs by tier."
  type        = map(string)
}

variable "instance_arns" {
  description = "EC2 instance ARNs by tier."
  type        = map(string)
}

variable "stop_schedule_expression" {
  description = "Cron expression used to stop instances."
  type        = string
}

variable "start_schedule_expression" {
  description = "Cron expression used to start instances."
  type        = string
}

variable "schedule_timezone" {
  description = "Schedule timezone."
  type        = string
}

variable "tags" {
  description = "Common tags."
  type        = map(string)
}
