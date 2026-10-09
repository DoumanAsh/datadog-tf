resource "datadog_logs_custom_pipeline" "this" {
  filter {
    query = "service:elb"
  }

  name        = "AWS ELB Logs Enrichment"
  description = "Pipeline to enrich AWS ELB logs with useful attributes. This pipeline relies on builtin AWS integration"
  is_enabled  = var.is_enabled

  ## Basic extraction to get service and method
  processor {
    grok_parser {
      grok {
        match_rules   = "ApiCall /%%{regex(\"[a-zA-Z][^/]+\"):api.service}/%%{data:api.method}"
        support_rules = ""
      }
      source = "http.url_details.path"
      name   = "Extract api.service amd api.method from path"
    }
  }

  ## Parser for x-ray trace id
  processor {
    grok_parser {
      grok {
        match_rules   = "traceId %%{integer}-%%{regex(\"[A-Fa-f0-9]+\"):xray_time}-%%{regex(\"[A-Fa-f0-9]+\"):xray_id}"
        support_rules = ""
      }
      source = "TraceId"
      name   = "Extracts xray_id and xray_time from X-Ray TraceId"
    }
  }

  processor {
    string_builder_processor {
      name               = "Construct trace_id from xray_*"
      template           = "%%{xray_time}%%{xray_id}"
      target             = "trace_id"
      is_replace_missing = false
    }
  }

  processor {
    exclude_attribute_processor {
      name                 = "Remove xray_id"
      attribute_to_exclude = "xray_id"
    }
  }

  processor {
    exclude_attribute_processor {
      name                 = "Remove xray_time"
      attribute_to_exclude = "xray_time"
    }
  }

  processor {
    trace_id_remapper {
      name    = "Use trace_id"
      sources = ["trace_id"]
    }
  }
}
