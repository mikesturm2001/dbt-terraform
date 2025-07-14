variable "dbtcloud_account_id" {
  type        = string
  description = "dbt Cloud Account ID"
}

variable "dbtcloud_token" {
  type        = string
  description = "dbt Cloud API Token"
  sensitive   = true
}

variable "dbtcloud_host_url" {
  type        = string
  description = "dbt Cloud Host URL"
  default     = "https://cloud.getdbt.com"
}

variable "project_id" {
  type        = string
  description = "dbt Cloud Project ID (from central infrastructure)"
}

variable "team_name" {
  type        = string
  description = "Name of your team"
  default     = "marketing-team"
}

variable "jobs" {
  type = list(object({
    name                = string
    description         = optional(string, "")
    environment_id      = string
    execute_steps       = list(string)
    triggers_on_draft_pr = optional(bool, false)
    schedule_type       = optional(string, "every_day")
    schedule_hours      = optional(list(number), [])
    schedule_days       = optional(list(number), [])
    schedule_date       = optional(string, null)
    cron_schedule       = optional(string, null)
    job_type           = optional(string, "daily")
    threads            = optional(number, 4)
    target_name        = optional(string, null)
    generate_docs      = optional(bool, false)
  }))
  description = "List of dbt Cloud jobs to create for this team"
  default     = []
}