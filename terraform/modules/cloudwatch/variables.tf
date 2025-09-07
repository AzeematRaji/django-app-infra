variable "auto_scaling_group_name" {
  description = "Name of the Auto Scaling Group"
  type        = string
}

variable "load_balancer_arn_suffix" {
  description = "ARN suffix of the load balancer"
  type        = string
}

variable "rds_instance_id" {
  description = "RDS instance identifier"
  type        = string
}

variable "scale_up_policy_arn" {
  description = "ARN of the scale up policy"
  type        = string
  default     = ""
}

variable "scale_down_policy_arn" {
  description = "ARN of the scale down policy"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}