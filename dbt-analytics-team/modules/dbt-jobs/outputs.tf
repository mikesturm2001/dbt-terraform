output "job_ids" {
  description = "List of created job IDs"
  value       = dbtcloud_job.team_jobs[*].id
}

output "job_names" {
  description = "List of created job names"
  value       = dbtcloud_job.team_jobs[*].name
}

output "jobs_info" {
  description = "Detailed information about created jobs"
  value = {
    for idx, job in dbtcloud_job.team_jobs : job.name => {
      id             = job.id
      name           = job.name
      description    = job.description
      project_id     = job.project_id
      environment_id = job.environment_id
      execute_steps  = job.execute_steps
      job_type       = local.filtered_jobs[idx].job_type
    }
  }
}

output "deployment_info" {
  description = "Information about job deployment decisions"
  value = {
    target_environment    = var.target_environment
    target_env_allows_jobs = local.can_deploy_jobs
    jobs_requested        = length(var.jobs)
    jobs_deployed         = length(local.filtered_jobs)
    skipped_jobs = [
      for job in var.jobs : job.name
      if !contains([for filtered in local.filtered_jobs : filtered.name], job.name)
    ]
  }
}