output "id" {
  description = "Pipeline ID to be plugged into datadog_logs_pipeline_order"
  value       = datadog_logs_custom_pipeline.this.id
}
