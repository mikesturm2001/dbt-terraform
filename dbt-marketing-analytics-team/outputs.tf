# Marketing Analytics Team Job Outputs

output "deployment_info" {
  description = "Information about the Marketing Analytics Team job deployment"
  value = {
    team_name      = var.team_name
    project_id     = var.project_id
    environment_id = var.environment_id
    total_jobs     = length(var.jobs)
  }
}

output "created_jobs" {
  description = "Details of created Marketing Analytics Team jobs"
  value       = module.team_jobs.created_jobs
}

output "job_summary" {
  description = "Summary of Marketing Analytics Team jobs by type"
  value       = module.team_jobs.job_summary
}