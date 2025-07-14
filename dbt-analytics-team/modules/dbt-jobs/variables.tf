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
  description = "dbt Cloud Project ID where jobs will be created"
}

variable "environment_id" {
  type        = string
  description = "dbt Cloud Environment ID to use for jobs"
}


variable "jobs" {
  type = list(object({
    name                = string
    description         = optional(string, "")
    execute_steps       = list(string)
    triggers_on_draft_pr = optional(bool, false)
    schedule_type       = optional(string, "every_day")
    schedule_hours      = optional(list(number), [])
    schedule_days       = optional(list(number), [])
    job_type           = optional(string, "daily")
  }))
  description = "List of dbt Cloud jobs to create"
  default     = []
}

variable "team_name" {
  type        = string
  description = "Name of the team (used for naming convention)"
}