locals {
  widget_tags          = [for variable in var.template_variables : format("$%s", variable.name)]
  query_from_tags_list = join(",", local.widget_tags)

  json_template_variables = [for variable in var.template_variables : {
    name : variable.name,
    prefix : variable.name,
    defaults : variable.defaults,
  }]

  json_duration_format = {
    unit : {
      type : "canonical_unit",
      unit_name : "second"
    },
    precision : 2,
    unit_scale : {
      type : "canonical_unit",
      unit_name : "minute"
    }
  }

  json_upcoming_runs = {
    id : 2,
    layout : {
      x : 0,
      y : 4,
      width : 12,
      height : 4
    }
    definition : {
      title : "Upcoming runs",
      show_title : true,
      type : "group",
      layout_type : "ordered",

      widgets : [
        for idx, cron_schedule in var.cronjobs_schedule : {
          id : 10 + idx,
          layout : {
            x : (idx % 4) * 3,
            y : floor(idx / 4) * 2,
            width : 3,
            height : 2,
          }
          definition : {
            title : cron_schedule.title == null ? cron_schedule.name : cron_schedule.title
            title_size : "16",
            title_align : "left",
            autoscale : true,
            precision : 2
            type : "query_value",
            requests : [
              {
                response_format : "scalar",
                queries : [
                  {
                    data_source : "metrics",
                    name : "last_schedule",
                    query : "avg:kubernetes_state.cronjob.duration_since_last_schedule{${join(",", concat(local.widget_tags, ["kube_cronjob:${cron_schedule.name}"]))}}",
                    aggregator : "last"
                  }
                ],
                formulas : [
                  {
                    number_format : {
                      unit : {
                        type : "canonical_unit",
                        unit_name : "second"
                      }
                    },
                    formula : "${cron_schedule.interval_expr} - last_schedule"
                  }
                ]
              }
            ],

          }
        }
      ]
    }
  }
}

//API reference: https://docs.datadoghq.com/api/latest/dashboards/#create-a-new-dashboard
resource "datadog_dashboard_json" "dashboard" {
  dashboard = jsonencode({
    title              = var.title
    description        = var.description
    template_variables = local.json_template_variables
    layout_type        = "ordered"
    restricted_roles   = []
    widgets = [
      {
        id : 1
        definition : {
          title : "Schedule Status",
          title_size : "16",
          title_align : "left",
          type : "check_status",
          check : "kubernetes_state.cronjob.on_schedule_check",
          grouping : "cluster",
          group : "$env",
          group_by : [
            "kube_cronjob"
          ],
          tags : [
            "$env"
          ]
        },
        layout : {
          x : 0,
          y : 0,
          width : 2,
          height : 2
        }
      },
      local.json_upcoming_runs,
      {
        id : 100,
        definition : {
          title : "Cronjob Scheduling statistics",
          title_size : "16",
          title_align : "left",
          type : "query_table",
          requests : [
            {
              queries : [
                {
                  data_source : "metrics",
                  name : "last_schedule",
                  query : "avg:kubernetes_state.cronjob.duration_since_last_schedule{${local.query_from_tags_list}} by {kube_cronjob}",
                  aggregator : "last"
                },
                {
                  data_source : "metrics",
                  name : "last_success",
                  query : "avg:kubernetes_state.cronjob.duration_since_last_successful{${local.query_from_tags_list}} by {kube_cronjob}",
                  aggregator : "last"
                },
                {
                  data_source : "metrics",
                  name : "is_suspend",
                  query : "max:kubernetes_state.cronjob.spec_suspend{${local.query_from_tags_list}} by {kube_cronjob}",
                  aggregator : "last"
                }
              ],
              response_format : "scalar",
              sort : {
                count : 500,
                order_by : [
                  {
                    type : "formula",
                    index : 0,
                    order : "asc"
                  }
                ]
              },
              formulas : [
                {
                  alias : "Last schedule",
                  cell_display_mode : "number",
                  number_format : local.json_duration_format,
                  formula : "last_schedule"
                },
                {
                  alias : "Last success",
                  cell_display_mode : "number",
                  number_format : local.json_duration_format,
                  formula : "last_success"
                },
                {
                  alias : "Suspended?",
                  conditional_formats : [
                    {
                      comparator : "=",
                      value : 0,
                      palette : "white_on_green"
                    },
                    {
                      comparator : ">",
                      value : 0,
                      palette : "white_on_yellow"
                    }
                  ],
                  cell_display_mode : "number",
                  number_format : {
                    unit : {
                      type : "canonical_unit"
                    },
                    precision : 0
                  },
                  formula : "is_suspend"
                }
              ]
            }
          ],
          has_search_bar : "auto"
        },
        layout : {
          x : 0,
          y : 8,
          width : 12,
          height : 6
        }
      }
    ]
  })
}
