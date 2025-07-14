terraform {
  required_providers {
    dbtcloud = {
      source  = "dbt-labs/dbtcloud"
      version = "~> 0.3"
    }
  }
}

# dbt Cloud Jobs
resource "dbtcloud_job" "team_jobs" {
  count         = length(var.jobs)
  project_id    = var.project_id
  environment_id = var.environment_id
  
  name          = "${var.team_name}-${var.jobs[count.index].name}"
  description   = var.jobs[count.index].description
  execute_steps = var.jobs[count.index].execute_steps
  
  triggers {
    github_webhook = false
    git_provider_webhook = false
    schedule = true
    on_merge = false
  }
  
  # Schedule configuration
  schedule {
    cron = var.jobs[count.index].schedule_type == "custom" ? "0 ${join(",", var.jobs[count.index].schedule_hours)} * * ${join(",", var.jobs[count.index].schedule_days)}" : null
    
    dynamic "days" {
      for_each = var.jobs[count.index].schedule_type != "custom" ? [1] : []
      content {
        daily = var.jobs[count.index].schedule_type == "every_day" ? true : false
        weekly = var.jobs[count.index].schedule_type == "weekly" ? var.jobs[count.index].schedule_days : null
      }
    }
    
    dynamic "hours" {
      for_each = var.jobs[count.index].schedule_type != "custom" && length(var.jobs[count.index].schedule_hours) > 0 ? [1] : []
      content {
        interval = var.jobs[count.index].schedule_hours
      }
    }
  }
  
  # Default settings
  dbt_version              = null  # Use environment default
  threads                  = 4
  target_name             = null   # Use environment default
  generate_docs           = true
  run_generate_sources    = false
  defer_to_prod           = false
}