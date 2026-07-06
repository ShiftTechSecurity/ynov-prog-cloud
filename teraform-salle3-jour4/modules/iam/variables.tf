variable "name_prefix" {
  description = "Resource name prefix."
  type        = string
}

variable "metric_namespace" {
  description = "CloudWatch namespace allowed for custom application metrics."
  type        = string
}

variable "tags" {
  description = "Common tags."
  type        = map(string)
}
