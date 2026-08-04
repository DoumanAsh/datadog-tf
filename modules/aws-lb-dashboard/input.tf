variable "title" {
  description = "Title of the dashboard"
  type        = string
  default     = "[TF] AWS LB Gateway"
}

variable "description" {
  description = "Description of the dashboard"
  type        = string
  default     = "Summarizes status of AWS WAF and LBs"
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
