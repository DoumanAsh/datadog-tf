# AWS Load Balancer Dashboard

Provides overview of WAR and ELB from your AWS account

## Parameters

Full list of parameters with their default values can be found in [input.tf](./input.tf)

Following parameters can be specified

| Parameter           | Description |
|---------------------|-------------|
| `title`             | Title of the dashboard. Defaults to `[TF] AWS LB Gateway` |
| `description`       | Brief description of your dashboard. Defaults to `Summarizes status of AWS WAF and LBs` |
| `restricted_roles`  | List of UUIDs of users who should be allowed to edit. Defaults to None |
| `template_variables`| List of template variables to use in addition to the standard ones |
