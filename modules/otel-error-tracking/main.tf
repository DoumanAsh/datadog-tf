resource "datadog_logs_custom_pipeline" "this" {
  filter {
    query = "source:otlp_log_ingestion otel.severity_text:ERROR"
  }

  name       = "OTEL Error Tracking"
  is_enabled = var.is_enabled

  # Kind is important to have as unique property for purpose of grouping
  # e.g. In case you want separate errors from exceptions
  processor {
    string_builder_processor {
      target   = "error.kind"
      template = "error"
    }
  }

  ## Basic extraction of error body into error.message
  processor {
    grok_parser {
      grok {
        match_rules   = "MESSAGE %%{data:error.message}"
        support_rules = ""
      }
      source = "message"
      name   = "ExtractLogMessage"
    }
  }

  ## Extracts severity
  processor {
    category_processor {
      name   = "SeverityNumber"
      target = "status"

      category {
        name = "TRACE"
        filter {
          query = "@otel.severity_number:[1-4]"
        }
      }

      category {
        name = "DEBUG"
        filter {
          query = "@otel.severity_number:[5-8]"
        }
      }

      category {
        name = "INFO"
        filter {
          query = "@otel.severity_number:[9-12]"
        }
      }

      category {
        name = "WARN"
        filter {
          query = "@otel.severity_number:[13-16]"
        }
      }

      category {
        name = "ERROR"
        filter {
          query = "@otel.severity_number:[17-20]"
        }
      }

      category {
        name = "CRITICAL"
        filter {
          query = "@otel.severity_number:[21-24]"
        }
      }
    }
  }

  processor {
    attribute_remapper {
      name            = "SeverityText"
      source_type     = "attribute"
      sources         = ["otel.severity_text"]
      target          = "status"
      target_type     = "attribute"
      is_enabled      = true
      preserve_source = false
      # you might propagate status automatically via datadog, so no need to do extra override
      override_on_conflict = false
    }
  }

  ## Exception remapping
  ## Exception will be delivered to error log most of the time, so we override default error log rules above
  processor {
    attribute_remapper {
      name            = "ExceptionType"
      source_type     = "attribute"
      sources         = ["exception.type"]
      target          = "error.kind"
      target_type     = "attribute"
      is_enabled      = true
      preserve_source = false
      # you might propagate version automatically via datadog, so no need to do extra override
      override_on_conflict = false
    }
  }

  processor {
    attribute_remapper {
      name            = "ExceptionMessage"
      source_type     = "attribute"
      sources         = ["exception.message"]
      target          = "error.message"
      target_type     = "attribute"
      is_enabled      = true
      preserve_source = false
      # you might propagate version automatically via datadog, so no need to do extra override
      override_on_conflict = false
    }
  }

  processor {
    attribute_remapper {
      name            = "ExceptionStacktrace"
      source_type     = "attribute"
      sources         = ["exception.stacktrace"]
      target          = "error.stack"
      target_type     = "attribute"
      is_enabled      = true
      preserve_source = false
      # you might propagate version automatically via datadog, so no need to do extra override
      override_on_conflict = false
    }
  }

  ## Guarantee common datadog properties remapping
  ## Use common remapper rather than specialized to remove original attributes for sure
  ## Service info
  processor {
    attribute_remapper {
      name            = "ServiceName"
      source_type     = "attribute"
      sources         = ["service.name"]
      target          = "service"
      target_type     = "attribute"
      is_enabled      = true
      preserve_source = false
      # you might propagate service automatically via datadog, so no need to do extra override
      override_on_conflict = false
    }
  }

  processor {
    attribute_remapper {
      name            = "ServiceVersion"
      source_type     = "attribute"
      sources         = ["service.version"]
      target          = "version"
      target_type     = "attribute"
      is_enabled      = true
      preserve_source = false
      # you might propagate version automatically via datadog, so no need to do extra override
      override_on_conflict = false
    }
  }

  processor {
    attribute_remapper {
      name            = "ServiceEnv"
      source_type     = "attribute"
      sources         = ["deployment.environment.name"]
      target          = "env"
      target_type     = "attribute"
      is_enabled      = true
      preserve_source = false
      # you might propagate env automatically via datadog, so no need to do extra override
      override_on_conflict = false
    }
  }

  ## Trace/span info
  processor {
    trace_id_remapper {
      name       = "TraceId"
      sources    = ["otel.trace_id"]
      is_enabled = true
    }
  }

  processor {
    span_id_remapper {
      name       = "SpanId"
      sources    = ["otel.span_id"]
      is_enabled = true
    }
  }

  ## Container info
  processor {
    attribute_remapper {
      name                 = "ContainerId"
      source_type          = "attribute"
      sources              = ["container.id"]
      target               = "container_id"
      target_type          = "attribute"
      is_enabled           = true
      preserve_source      = false
      override_on_conflict = false
    }
  }

  processor {
    attribute_remapper {
      name                 = "ContainerName"
      source_type          = "attribute"
      sources              = ["container.name"]
      target               = "container_name"
      target_type          = "attribute"
      is_enabled           = true
      preserve_source      = false
      override_on_conflict = false
    }
  }

  ## Host info
  processor {
    attribute_remapper {
      name                 = "Host"
      source_type          = "attribute"
      sources              = ["host.name", "host.id"]
      target               = "host"
      target_type          = "attribute"
      is_enabled           = true
      preserve_source      = false
      override_on_conflict = false
    }
  }
}
