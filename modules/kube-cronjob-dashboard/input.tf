variable "title" {
  description = "Title of the dashboard"
  type        = string
  default     = "[TF] Kubernetes Cronjob Dashboard"
}

variable "description" {
  description = "Description of the dashboard"
  type        = string
  default     = "Summarizes status of the Kubernetes's cronjobs"
}

variable "restricted_roles" {
  description = "List of user's UUID that are allowed to edit dashboard"
  type        = list(string)
  default     = []
}

variable "template_variables" {
  description = "List of template variables to set"
  type = list(object({
    name     = string
    defaults = optional(list(string), [])
  }))
  default = []
}

variable "cronjobs_schedule" {
  description = "List of cronjob schedules"
  type = list(object({
    # Cron job name
    name = string,
    # Optional title for widget
    title = optional(string)
    # Expression that evaluates into interval duration in seconds
    interval_expr = string
  }))
  default = []
}
