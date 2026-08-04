locals {
  widget_tags                 = [for variable in var.template_variables : format("$%s", variable.name)]
  query_from_tags_list        = join(" ", local.widget_tags)
  metric_query_from_tags_list = join(",", local.widget_tags)

  json_template_variables = [for variable in var.template_variables : {
    name : variable.name,
    prefix : variable.name,
    defaults : variable.defaults,
  }]
}

resource "datadog_dashboard_json" "lb_dashboard" {
  dashboard = jsonencode({
    title       = var.title
    description = var.description
    template_variables = concat(local.json_template_variables, [
      {
        name    = "action",
        prefix  = "@system.action",
        default = "*"
      },
      {
        name    = "method",
        prefix  = "@http.method",
        default = "*"
      },
      {
        name    = "RequestHost",
        prefix  = "@httpRequest.host",
        default = "*"
      },
      {
        name   = "content_type",
        prefix = "@httpRequest.headers.content-type",
        available_values = [
          "\"application/grpc\""
        ],
        default = "*"
      },
      {
        name    = "Status",
        prefix  = "@http.status_code",
        default = "*"
      },
      {
        name    = "exclude_path",
        prefix  = "@http.url_details.path",
        default = "*HealthCheck"
      },
      {
        name    = "include_path",
        prefix  = "@http.url_details.path",
        default = "*"
      }

    ]),
    restricted_roles   = var.restricted_roles
    layout_type        = "ordered",
    notify_list        = [],
    pause_auto_refresh = false,
    reflow_type        = "fixed"
    widgets = [
      {
        id : 1,
        layout : {
          x : 0,
          y : 0,
          width : 9,
          height : 6
        },
        definition : {
          title : "Frequent WAF calls",
          title_size : "16",
          title_align : "left",
          show_legend : true,
          legend_layout : "vertical",
          legend_columns : [
            "avg",
            "max",
            "value",
            "min"
          ],
          type : "timeseries",
          requests : [
            {
              formulas : [
                {
                  formula : "query1"
                }
              ],
              queries : [
                {
                  name : "query1",
                  data_source : "logs",
                  search : {
                    query : "${local.query_from_tags_list} service:waf $action $method -$exclude_path $content_type $RequestHost $include_path"
                  },
                  indexes : [
                    "*"
                  ],
                  group_by : {
                    fields : [
                      "@http.url_details.path"
                    ],
                    limit : 30,
                    sort : {
                      aggregation : "count",
                      metric : "count",
                      order : "desc"
                    },
                    should_exclude_missing : true
                  },
                  compute : {
                    aggregation : "count"
                  },
                  storage : "hot"
                }
              ],
              response_format : "timeseries",
              style : {
                palette : "dog_classic",
                order_by : "values",
                line_type : "solid",
                line_width : "normal"
              },
              display_type : "line"
            }
          ]
        }
      }, //WAF Calls
      {
        id : 2,
        definition : {
          title : "WAF Requests by host",
          title_size : "16",
          title_align : "left",
          type : "toplist",
          requests : [
            {
              queries : [
                {
                  name : "query1",
                  data_source : "logs",
                  search : {
                    "query" : "${local.query_from_tags_list} service:waf $method -$exclude_path $content_type $RequestHost $include_path $action"
                  },
                  indexes : [
                    "*"
                  ],
                  group_by : {
                    fields : [
                      "@httpRequest.host"
                    ],
                    limit : 10,
                    sort : {
                      aggregation : "count",
                      metric : "count",
                      order : "desc"
                    },
                    should_exclude_missing : true
                  },
                  compute : {
                    "aggregation" : "count"
                  },
                  storage : "hot"
                }
              ],
              response_format : "scalar",
              formulas : [
                {
                  formula : "query1"
                }
              ],
              sort : {
                count : 10,
                order_by : [
                  {
                    type : "formula",
                    index : 0,
                    order : "desc"
                  }
                ]
              }
            }
          ],
          style : {
            display : {
              type : "stacked",
              legend : "automatic"
            }
          }
        },
        layout : {
          x : 9,
          y : 0,
          width : 3,
          height : 4
        }
      }, //WAF Requests by host
      {
        id : 3,
        definition : {
          title : "WAF actions",
          title_size : "16",
          title_align : "left",
          requests : [
            {
              queries : [
                {
                  name : "query1",
                  data_source : "logs",
                  search : {
                    query : "${local.query_from_tags_list} service:waf $method -$exclude_path $content_type $RequestHost $include_path $action"
                  },
                  indexes : [
                    "*"
                  ],
                  group_by : {
                    fields : [
                      "@system.action"
                    ],
                    limit : 10,
                    sort : {
                      aggregation : "count",
                      metric : "count",
                      order : "desc"
                    }
                  },
                  compute : {
                    aggregation : "count"
                  },
                  storage : "hot"
                }
              ],
              response_format : "scalar",
              style : {
                palette : "semantic"
              },
              formulas : [
                {
                  formula : "query1"
                }
              ],
              sort : {
                count : 500,
                order_by : [
                  {
                    type : "formula",
                    index : 0,
                    order : "desc"
                  }
                ]
              }
            }
          ],
          type : "sunburst",
          legend : {
            type : "inline"
          }
        },
        layout : {
          "x" : 9,
          "y" : 4,
          "width" : 3,
          "height" : 4
        }
      }, //WAF actions
      {
        id : 4,
        definition : {
          title : "WAF Logs",
          title_size : "16",
          title_align : "left",
          requests : [
            {
              response_format : "event_list",
              query : {
                data_source : "logs_stream",
                query_string : "${local.query_from_tags_list} service:waf $method -$exclude_path $content_type $RequestHost $include_path $action",
                storage : "hot"
              },
              columns : [
                {
                  field : "status_line",
                  width : "auto"
                },
                {
                  field : "timestamp",
                  width : "auto"
                },
                {
                  field : "@httpRequest.host",
                  width : "auto"
                },
                {
                  field : "@http.method",
                  width : "auto"
                },
                {
                  field : "@http.url_details.path",
                  width : "full"
                },
                {
                  field : "@network.client.ip",
                  width : "auto"
                },
                {
                  field : "@system.action",
                  width : "auto"
                },
                {
                  field : "@httpRequest.headers.user-agent",
                  width : "auto"
                }
              ]
            }
          ],
          type : "list_stream"
        },
        layout : {
          x : 0,
          y : 6,
          width : 9,
          height : 6
        }
      }, //WAF Logs
      {
        id : 10,
        definition : {
          title : "ELB Status codes",
          title_size : "16",
          title_align : "left",
          requests : [
            {
              queries : [
                {
                  name : "query1",
                  data_source : "logs",
                  search : {
                    "query" : "${local.query_from_tags_list} service:elb $method @http.url_details.host:$RequestHost.value -$exclude_path $include_path $Status"
                  },
                  indexes : [
                    "*"
                  ],
                  group_by : {
                    fields : [
                      "@http.status_code"
                    ],
                    limit : 30,
                    sort : {
                      aggregation : "count",
                      metric : "count",
                      order : "desc"
                    },
                    should_exclude_missing : true
                  },
                  compute : {
                    aggregation : "count"
                  },
                  storage : "hot"
                }
              ],
              response_format : "scalar",
              style : {
                palette : "semantic"
              },
              formulas : [
                {
                  formula : "query1"
                }
              ],
              sort : {
                count : 500,
                order_by : [
                  {
                    type : "formula",
                    index : 0,
                    order : "desc"
                  }
                ]
              }
            }
          ],
          type : "sunburst",
          legend : {
            type : "table"
          }
        },
        layout : {
          x : 9,
          y : 8,
          width : 3,
          height : 4
        }

      }, //ELB Status codes
      {
        id : 11,
        definition : {
          title : "ELB logs",
          title_size : "16",
          title_align : "left",
          requests : [
            {
              response_format : "event_list",
              query : {
                data_source : "logs_stream",
                query_string : "${local.query_from_tags_list} service:elb $method @http.url_details.host:$RequestHost.value -$exclude_path $include_path $Status",
                indexes : [],
                storage : "hot"
              },
              "columns" : [
                {
                  field : "status_line",
                  width : "auto"
                },
                {
                  field : "timestamp",
                  width : "auto"
                },
                {
                  field : "@http.url_details.host",
                  width : "auto"
                },
                {
                  field : "@http.status_code",
                  width : "auto"
                },
                {
                  field : "@http.url_details.path",
                  width : "full"
                },
                {
                  field : "@network.client.ip",
                  width : "auto"
                },
                {
                  field : "@http.url_details.port",
                  width : "auto"
                },
                {
                  field : "@http.useragent",
                  width : "auto"
                },
                {
                  field : "@duration",
                  width : "auto"
                }
              ]
            }
          ],
          type : "list_stream"
        },
        layout : {
          x : 0,
          y : 12,
          width : 12,
          height : 4
        }
      }, //ELB Log
      {
        id : 12,
        definition : {
          title : "ELB API calls error stats",
          title_size : "16",
          title_align : "left",
          type : "toplist",
          requests : [
            {
              queries : [
                {
                  name : "query1",
                  data_source : "logs",
                  search : {
                    query : "${local.query_from_tags_list} service:elb $method @http.url_details.host:$RequestHost.value -$exclude_path $include_path $Status @http.status_category:error"
                  },
                  indexes : [
                    "*"
                  ],
                  group_by : {
                    fields : [
                      "@http.url_details.path",
                      "@http.status_code"
                    ],
                    limit : 100,
                    sort : {
                      aggregation : "count",
                      metric : "count",
                      order : "desc"
                    },
                    should_exclude_missing : true
                  },
                  compute : {
                    aggregation : "count"
                  },
                  storage : "hot"
                }
              ],
              response_format : "scalar",
              formulas : [
                {
                  formula : "query1"
                }
              ],
              sort : {
                count : 100,
                order_by : [
                  {
                    type : "formula",
                    index : 0,
                    order : "desc"
                  }
                ]
              }
            }
          ],
          style : {
            display : {
              type : "stacked",
              legend : "automatic"
            },
            palette : "red"
          }
        },
        layout : {
          x : 0,
          y : 16,
          width : 6,
          height : 4
        }
      }, //ELB API calls error stats
      {
        id : 13,
        definition : {
          title : "ELB API calls OK stats",
          title_size : "16",
          title_align : "left",
          type : "toplist",
          requests : [
            {
              queries : [
                {
                  name : "query1",
                  data_source : "logs",
                  search : {
                    query : "${local.query_from_tags_list} service:elb $method @http.url_details.host:$RequestHost.value -$exclude_path $include_path $Status @http.status_category:OK"
                  },
                  indexes : [
                    "*"
                  ],
                  group_by : {
                    fields : [
                      "@http.url_details.path",
                      "@http.status_code"
                    ],
                    limit : 100,
                    sort : {
                      aggregation : "count",
                      metric : "count",
                      order : "desc"
                    },
                    should_exclude_missing : true
                  },
                  compute : {
                    aggregation : "count"
                  },
                  storage : "hot"
                }
              ],
              response_format : "scalar",
              formulas : [
                {
                  formula : "query1"
                }
              ],
              sort : {
                count : 100,
                order_by : [
                  {
                    type : "formula",
                    index : 0,
                    order : "desc"
                  }
                ]
              }
            }
          ],
          style : {
            display : {
              type : "stacked",
              legend : "automatic"
            },
            palette : "green"
          }
        },
        layout : {
          x : 6,
          y : 16,
          width : 6,
          height : 4
        }
      }, //ELB API calls OK stats
      {
        id : 20,
        definition : {
          title : "P95 Backend processing",
          title_size : "16",
          title_align : "left",
          show_legend : true,
          legend_layout : "auto",
          legend_columns : [
            "avg",
            "min",
            "max",
            "value",
            "sum"
          ],
          type : "timeseries",
          requests : [
            {
              formulas : [
                {
                  number_format : {
                    unit : {
                      type : "canonical_unit",
                      unit_name : "millisecond"
                    }
                  },
                  alias : "Backend",
                  style : {
                    palette : "dog_classic"
                  },
                  formula : "query1"
                }
              ],
              queries : [
                {
                  name : "query1",
                  data_source : "logs",
                  search : {
                    query : "${local.query_from_tags_list} service:elb $method @http.url_details.host:$RequestHost.value -$exclude_path $include_path $Status -@elb.performance.backend_processing_time:\"-1\""
                  },
                  indexes : [
                    "*"
                  ],
                  group_by : {
                    fields : [
                      "@http.url_details.path"
                    ],
                    limit : 10,
                    sort : {
                      aggregation : "pc95",
                      metric : "@elb.performance.backend_processing_time",
                      order : "desc"
                    },
                    should_exclude_missing : true
                  },
                  compute : {
                    aggregation : "pc95",
                    metric : "@elb.performance.backend_processing_time"
                  },
                  storage : "hot"
                }
              ],
              response_format : "timeseries",
              style : {
                palette : "dog_classic",
                order_by : "values",
                line_type : "solid",
                line_width : "normal"
              },
              display_type : "line"
            }
          ]
        },
        layout : {
          x : 0,
          y : 20,
          width : 6,
          height : 4
        }
      }, //P95 Backend processing
      {
        id : 21,
        definition : {
          title : "P99 Backend processing",
          title_size : "16",
          title_align : "left",
          show_legend : true,
          legend_layout : "auto",
          legend_columns : [
            "avg",
            "min",
            "max",
            "value",
            "sum"
          ],
          type : "timeseries",
          requests : [
            {
              formulas : [
                {
                  number_format : {
                    unit : {
                      type : "canonical_unit",
                      unit_name : "millisecond"
                    }
                  },
                  alias : "Backend",
                  style : {
                    palette : "dog_classic"
                  },
                  formula : "query1"
                }
              ],
              queries : [
                {
                  name : "query1",
                  data_source : "logs",
                  search : {
                    query : "${local.query_from_tags_list} service:elb $method @http.url_details.host:$RequestHost.value -$exclude_path $include_path $Status -@elb.performance.backend_processing_time:\"-1\""
                  },
                  indexes : [
                    "*"
                  ],
                  group_by : {
                    fields : [
                      "@http.url_details.path"
                    ],
                    limit : 10,
                    sort : {
                      aggregation : "pc99",
                      metric : "@elb.performance.backend_processing_time",
                      order : "desc"
                    },
                    should_exclude_missing : true
                  },
                  compute : {
                    aggregation : "pc99",
                    metric : "@elb.performance.backend_processing_time"
                  },
                  storage : "hot"
                }
              ],
              response_format : "timeseries",
              style : {
                palette : "dog_classic",
                order_by : "values",
                line_type : "solid",
                line_width : "normal"
              },
              display_type : "line"
            }
          ]
        },
        layout : {
          x : 6,
          y : 20,
          width : 6,
          height : 4
        }
      }, //P99 Backend processing
      {
        id : 30,
        definition : {
          title : "ALB Service availability",
          title_size : "16",
          title_align : "left",
          show_legend : true,
          legend_layout : "vertical",
          legend_columns : [
            "value",
            "min",
            "max"
          ],
          time : {},
          type : "timeseries",
          requests : [
            {
              formulas : [
                {
                  number_format : {
                    unit : {
                      type : "canonical_unit",
                      unit_name : "percent"
                    },
                    unit_scale : {
                      type : "canonical_unit",
                      unit_name : "percent"
                    }
                  },
                  alias : "Host Availability",
                  formula : "exclude_null(query1) / (exclude_null(query1) + exclude_null(query2)) * 100"
                }
              ],
              queries : [
                {
                  "data_source" : "metrics",
                  "name" : "query1",
                  "query" : "avg:aws.applicationelb.healthy_host_count{${local.metric_query_from_tags_list}} by {ingress.eks.amazonaws.com/resource}"
                },
                {
                  "data_source" : "metrics",
                  "name" : "query2",
                  "query" : "avg:aws.applicationelb.un_healthy_host_count{${local.metric_query_from_tags_list}} by {ingress.eks.amazonaws.com/resource}"
                }
              ],
              response_format : "timeseries",
              style : {
                palette : "dog_classic",
                order_by : "values",
                line_type : "solid",
                line_width : "normal"
              },
              display_type : "line"
            }
          ]
        },
        layout : {
          x : 0,
          y : 24,
          width : 6,
          height : 6
        }
      }, //ALB Service availability
      {
        id : 31,
        definition : {
          title : "ALB Request Availability",
          title_size : "16",
          title_align : "left",
          description : "Percentage of non-500 requests. If ALB has no requests, assume 100% as there can be no errors without requests",
          show_legend : true,
          legend_layout : "vertical",
          legend_columns : [
            "min",
            "max",
            "value"
          ],
          type : "timeseries",
          requests : [
            {
              formulas : [
                {
                  number_format : {
                    unit : {
                      type : "canonical_unit",
                      unit_name : "percent"
                    },
                    unit_scale : {
                      type : "canonical_unit",
                      unit_name : "percent"
                    }
                  },
                  alias : "Availability",
                  style : {
                    palette : "green"
                  },
                  formula : "clamp_min(((clamp_min(exclude_null(query1), 1) - exclude_null(query2)) / clamp_min(exclude_null(query1), 1)) * 100, 0)"
                }
              ],
              queries : [
                {
                  data_source : "metrics",
                  name : "query1",
                  query : "sum:aws.applicationelb.request_count{${local.metric_query_from_tags_list}} by {ingress.eks.amazonaws.com/resource}.as_count()"
                },
                {
                  data_source : "metrics",
                  name : "query2",
                  query : "sum:aws.applicationelb.httpcode_elb_5xx{${local.metric_query_from_tags_list}} by {ingress.eks.amazonaws.com/resource}.as_count()"
                }
              ],
              response_format : "timeseries",
              style : {
                palette : "cool",
                order_by : "values",
                line_type : "solid",
                line_width : "normal"
              },
              display_type : "line"
            }
          ],
          yaxis : {
            include_zero : true,
            max : "100"
          },
          markers : []
        },
        layout : {
          x : 6,
          y : 24,
          width : 6,
          height : 3
        }
      }, //ALB Request Availability
      {
        id : 32,
        definition : {
          title : "ALB <200ms Availability",
          title_size : "16",
          title_align : "left",
          description : "Percentage of requests within 200ms",
          show_legend : true,
          legend_layout : "auto",
          legend_columns : [
            "avg",
            "min",
            "max",
            "value",
            "sum"
          ],
          type : "timeseries",
          requests : [
            {
              formulas : [
                {
                  number_format : {
                    unit : {
                      type : "canonical_unit",
                      unit_name : "percent"
                    },
                    unit_scale : {
                      type : "canonical_unit",
                      unit_name : "percent"
                    }
                  },
                  alias : "Availability",
                  style : {
                    palette : "green"
                  },
                  formula : "count(cutoff_max(query2, 0.2), { name }) / clamp_min(query1, 1) * 100"
                }
              ],
              queries : [
                {
                  data_source : "metrics",
                  name : "query1",
                  query : "sum:aws.applicationelb.request_count{${local.metric_query_from_tags_list}} by {name}.as_count()"
                },
                {
                  data_source : "metrics",
                  name : "query2",
                  query : "sum:aws.applicationelb.target_response_time.p95{${local.metric_query_from_tags_list}} by {name}"
                }
              ],
              response_format : "timeseries",
              style : {
                palette : "cool",
                order_by : "values",
                line_type : "solid",
                line_width : "normal"
              },
              display_type : "line"
            }
          ],
          markers : []
        },
        layout : {
          x : 6,
          y : 27,
          width : 6,
          height : 3
        }
      }, //ALB <200ms Availability
    ]
  })
}
