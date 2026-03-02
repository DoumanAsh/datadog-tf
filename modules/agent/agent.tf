locals {
  set_app_key = var.datadog_app_key == null ? [] : [
    {
      name  = "datadog.appKey"
      value = var.datadog_app_key
    },
  ]

  # datadog main params
  set_param_list = [
    {
      name  = "datadog.site"
      value = var.datadog_site
    },
    # Enable log collection
    {
      name  = "datadog.logs.enabled"
      value = var.log_collection
    },
    {
      name  = "datadog.logs.containerCollectAll"
      value = var.log_collection
    },
    {
      name  = "datadog.networkMonitoring.enabled"
      value = var.network_monitoring
    },
    {
      name  = "datadog.systemProbe.enableOOMKill"
      value = var.oom_kill_check
    },
  ]

  # Priority class setting
  set_datadog_priority_class = !var.enable_deployment_priority_class ? [] : [
    {
      name  = "agents.priorityClassCreate"
      value = var.enable_deployment_priority_class
    },
    {
      name  = "agents.priorityClassValue"
      value = var.deployment_priority_class_value
    },
    {
      name  = "agents.priorityPreemptionPolicyValue"
      value = var.deployment_priority_class_policy
    },
  ]

  # Cluster agent config
  set_cluster_agent_params = !var.datadog_cluster_agent ? tolist([]) : tolist([
    {
      name  = "clusterAgent.enabled"
      value = var.datadog_cluster_agent
    },
    {
      name  = "clusterAgent.metricsProvider.enabled"
      value = var.datadog_cluster_metrics_provider
    },
    {
      name  = "clusterAgent.admissionController.enabled"
      value = var.datadog_cluster_admission_controller
    },

    # High availability settings
    {
      name  = "clusterAgent.replicas"
      value = var.datadog_cluster_agent_ha ? 2 : 1
    },
    {
      name  = "clusterAgent.pdb.create"
      value = var.datadog_cluster_agent_ha
    },
  ])

  set_cluster_params = var.cluster_name == null ? [] : [
    {
      name  = "datadog.clusterName"
      value = var.cluster_name
    },
  ]

  # Setup OTLP if any receiver is enabled
  set_otlp_params = !var.otlp_grpc && !var.otlp_http ? [] : [
    {
      name  = "datadog.otlp.logs.enabled"
      value = var.log_collection
    },
    {
      name  = "datadog.otlp.receiver.protocols.grpc.enabled"
      value = var.otlp_grpc
    },
    {
      name  = "datadog.otlp.receiver.protocols.http.enabled"
      value = var.otlp_http
    },
  ]

  set_agent_resources = flatten([
    for boundary, resource_map in var.resources : [
      for resource_name, amount in resource_map : {
        name  = "agents.containers.agent.resources.${boundary}.${resource_name}"
        value = amount
      }
    ]
  ])
}

resource "helm_release" "this" {
  name            = "datadog-agent"
  chart           = "datadog"
  repository      = "https://helm.datadoghq.com"
  version         = var.chart_version
  namespace       = var.cluster_namespace
  atomic          = true
  cleanup_on_fail = true
  max_history     = 2

  set_sensitive = concat([
    {
      name  = "datadog.apiKey"
      value = var.datadog_api_key
    },
  ], local.set_app_key)

  set_list = [
    # Defines tag to attach to every data point sent by agent
    {
      name = "datadog.tags"
      value = [
        "env:${var.environment}"
      ]
    }
  ]

  set = concat(local.set_param_list, local.set_datadog_priority_class, local.set_cluster_agent_params, local.set_cluster_params, local.set_otlp_params, local.set_agent_resources)

  values = [
    # Define list of labels to extract and attach to pod's data points
    yamlencode({
      "datadog" : {
        "podLabelsAsTags" : {
          # label -> tag
          "${var.service_pod_label}" = "service"
          "${var.version_pod_label}" = "version"
        }
      }
    })
  ]
}
