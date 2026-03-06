variable "aws_account_id" {
  type        = string
  description = "AWS Account ID"
}

variable "environment" {
  description = "Environment name to identify integration with tag `env`"
  type        = string
}

variable "datadog_api_key" {
  type        = string
  sensitive   = true
  description = "Datadog API Key"
}

variable "datadog_app_key" {
  type        = string
  sensitive   = true
  description = <<EOF
    Datadog Application Key. Required for the AWS integration setup.

    At least following permissions must be set:
    - aws_configuration_edit
    - aws_configuration_read
    - aws_configurations_manage
  EOF
}

variable "datadog_aws_account_id" {
  type        = string
  default     = "464622532012"
  description = "Datadog AWS account used for integration. Can be found on https://docs.datadoghq.com/integrations/guide/aws-manual-setup/?tab=roledelegation&site=us. Defaults to US"
}

variable "datadog_api_url" {
  type        = string
  default     = "https://api.datadoghq.com"
  description = "Datadog API Url. Possible value for every region can be found on https://docs.datadoghq.com/getting_started/site/. Defaults to US"
}
