# Terraform configuration for Analytics Team dbt Cloud jobs

provider "dbtcloud" {
  account_id = var.dbtcloud_account_id
  token      = var.dbtcloud_token
  host_url   = var.dbtcloud_host_url
}

# Create dbt Cloud jobs directly with for_each loop
resource "dbtcloud_job" "team_jobs" {
  for_each = { for job in var.jobs : job.name => job }

  account_id    = var.dbtcloud_account_id
  project_id    = var.project_id
  environment_id = each.value.environment_id
  
  name         = "${var.team_name}-${each.value.name}"
  description  = each.value.description
  execute_steps = each.value.execute_steps
  
  triggers_on_draft_pr = each.value.triggers_on_draft_pr

  # Schedule configuration
  triggers = {
    schedule = each.value.schedule_type != "manual"
  }
  
  schedule = each.value.schedule_type != "manual" ? {
    cron        = each.value.schedule_type == "cron" ? each.value.cron_schedule : null
    date        = each.value.schedule_type == "specific_date" ? each.value.schedule_date : null
    days        = each.value.schedule_type == "every_day" ? [1, 2, 3, 4, 5, 6, 7] : each.value.schedule_days
    hours       = each.value.schedule_hours
  } : null

  # Job settings
  settings = {
    threads       = try(each.value.threads, 4)
    target_name   = try(each.value.target_name, null)
    generate_docs = try(each.value.generate_docs, false)
  }
}