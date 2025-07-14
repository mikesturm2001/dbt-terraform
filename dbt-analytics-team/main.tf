# Use the dbt-jobs module to create team-specific jobs
module "team_jobs" {
  source = "./modules/dbt-jobs"

  dbtcloud_account_id = var.dbtcloud_account_id
  dbtcloud_token      = var.dbtcloud_token
  dbtcloud_host_url   = var.dbtcloud_host_url
  
  project_id     = var.project_id
  team_name      = var.team_name
  
  # Direct environment ID assignment
  environment_id = var.environment_id
  
  # Use jobs from tfvars
  jobs = var.jobs
}