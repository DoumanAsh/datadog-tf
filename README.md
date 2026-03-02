# datadog terraform modules

[![Tofu](https://github.com/DoumanAsh/datadog-tf/actions/workflows/tofu.yaml/badge.svg)](https://github.com/DoumanAsh/datadog-tf/actions/workflows/tofu.yaml)

Utility modules to setup datadog components

## Modules

- [agent](modules/agent) - Wrapper module to provide convenient setup of datadog agent helm chart
- [otel-error-tracking](modules/otel-error-tracking) - Defines Opentelemetry logging pipeline to convert error logs for [Datadog Error Tracking](https://docs.datadoghq.com/logs/error_tracking/)
