###########################
## Datadog main parameters
###########################
variable "datadog_site" {
  description = "Datadog site to send data to"
  type        = string
  default     = "datadogqh.com"
}

variable "datadog_api_url" {
  description = "Datadog server API URL"
  type        = string
  default     = "https://api.datadoghq.com"
}

variable "datadog_api_key" {
  description = "API key to connect to Datadog server for agent"
  type        = string
  sensitive   = true
}

variable "datadog_app_key" {
  description = "Datadog Application key to be used with metrics provider"
  type        = string
  default     = null
  sensitive   = true
}

###########################
## Helm chart parameters
###########################
variable "chart_version" {
  description = "Helm chart version to use"
  type        = string
  default     = null
}

variable "cluster_namespace" {
  description = "Kubernetes into which to install agent"
  type        = string
  default     = "default"
}

###########################
## Agent deployment parameters
###########################
variable "resources" {
  description = "Configures deployed agent resource constraints"
  type = object({
    requests = optional(map(string), {})
    limits   = optional(map(string), {})
  })
  default = {}
}

variable "enable_deployment_priority_class" {
  description = "Specifies to deploy datadog agent with priority class to ensure its high availability even when cluster is constrained by resources"
  type        = bool
  default     = false
}

variable "deployment_priority_class_value" {
  description = "Specifies priority class value"
  type        = number
  default     = 1000000000
}

variable "deployment_priority_class_policy" {
  description = "Specifies priority class preemption policy"
  type        = string
  default     = "PreemptLowerPriority"
}

variable "log_collection" {
  description = "Specifies whether to enable log collection by the agent"
  type        = bool
  default     = false
}

variable "event_collection" {
  description = "Specifies whether to enable kubernetes event collection by the agent"
  type        = bool
  default     = false
}

variable "network_monitoring" {
  description = "Enable network performance metrics collection"
  type        = bool
  default     = false
}

variable "oom_kill_check" {
  description = "Enable OOM Killer based on oneBPF program in the System Probe"
  type        = bool
  default     = false
}

variable "cluster_name" {
  description = "Defines cluster name to pass to the datadog agent"
  type        = string
  default     = null
}

variable "environment" {
  description = "Environment name to identify deployment. Attached as `env` tag when agent sends data"
  type        = string
}

variable "service_pod_label" {
  description = "Defines name of the label to treat as 'service' tag"
  type        = string
  default     = "app"
}

variable "version_pod_label" {
  description = "Defines name of the label to treat as 'version' tag"
  type        = string
  default     = "version"
}

variable "otlp_grpc" {
  description = "Specifies whether to enable OTLP gRPC receiver on agent. Accessible on port 4317"
  type        = bool
  default     = false
}

variable "otlp_http" {
  description = "Specifies whether to enable OTLP HTTP receiver on agent. Accessible on port 4318"
  type        = bool
  default     = false
}

###########################
## Cluster Agent deployment parameters
###########################
variable "datadog_cluster_agent" {
  description = "Specifies whether to enable Cluster Agent"
  type        = bool
  default     = false
}

variable "datadog_cluster_agent_ha" {
  description = "Specifies whether to enable High Availability setting on the agent"
  type        = bool
  default     = false
}

variable "datadog_cluster_metrics_provider" {
  description = "Specifies whether to enable metrics provider within Cluster Agent"
  type        = bool
  default     = false
}

variable "datadog_cluster_admission_controller" {
  description = "Automatically injects datadog SDK environment variables and attaches unified tags. Read more https://docs.datadoghq.com/containers/cluster_agent/admission_controller/?tab=datadogoperator"
  type        = bool
  default     = false
}
