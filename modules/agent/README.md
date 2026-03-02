# Datadog Agent Module

This module wraps [helm chart](https://github.com/DataDog/helm-charts/blob/main/charts/datadog/README.md) to provide a simplified configuration with parameters that are of actual interest to be customized

## Mandatory parameters

Full list of parameters with their default values can be found in [input.tf](./input.tf)

Following parameters MUST be specified to deploy helm chart

| Parameter         | Description |
|-------------------|-------------|
| `datadog_api_key` | API key to be used |
| `environment`     | Descriptive name for cluster environment to be unique `env` tag for your applications |

## Unified tagging

This module aims to ensure every application is tagged to be uniquely identified by means of automatic datadog agent's tagging.

This is achieved by setting `env` tag via setting `datadog.tags` and
enabling `version`/`service` mapping via `datadog.podLabelsAsTags` setting

| Tag        | Description |
|------------|-------------|
| `env`      | Deployment environment. Automatically annotated by agent from value of `environment` variable |
| `version`  | Unique version. Taken from pod label, if specified. Pod label is defined via `version_pod_label`. Defaults to `version` |
| `service`  | Unique name of application. Taken from pod label, if specified. Pod label is defined via `service_pod_label`. Defaults to `app` |
