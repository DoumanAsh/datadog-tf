# Kubernetes cronjob dashboard

Provides a way to initialize simple cronjob dashboard to monitor status of your jobs

## Parameters

Full list of parameters with their default values can be found in [input.tf](./input.tf)

Following parameters can be specified

| Parameter           | Description |
|---------------------|-------------|
| `title`             | Title of the dashboard. Defaults to `[TF] Kubernetes Cronjob Dashboard` |
| `description`       | Brief description of your dashboard. Defaults to `Summarizes status of the Kubernetes's cronjobs` |
| `restricted_roles`  | List of UUIDs of users who should be allowed to edit. Defaults to None |
| `template_variables`| List of tags to be used as template variables. Defaults to None. Recommended values are at least `env` to select environment |
| `cronjobs_schedule` | List of cronjob schedules with `name` matching `kube_cronjob` label and `interval_expr` returning duration in seconds, indicating interval between cronjob runs. Defaults to None |
