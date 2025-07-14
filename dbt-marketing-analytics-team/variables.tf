# dbt Cloud Configuration
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

# Team Configuration
variable "team_name" {
  type        = string
  description = "Name of the team"
  default     = "marketing-team"
}

# Project and Environment (from platform team)
variable "project_id" {
  type        = string
  description = "dbt Cloud Project ID for Marketing Analytics (from platform team output)"
}

variable "environment_id" {
  type        = string
  description = "dbt Cloud Environment ID to deploy jobs to"
}

# Jobs Configuration
variable "jobs" {
  type = list(object({
    name          = string
    description   = string
    execute_steps = list(string)
    schedule_type = string
    schedule_hours = optional(list(number), [])
    schedule_days  = optional(list(number), [])
    job_type      = string
    threads       = optional(number, 4)
    generate_docs = optional(bool, true)
    run_generate_sources = optional(bool, false)
    target_name   = optional(string, null)
  }))
  description = "List of Marketing Analytics Team dbt jobs to create"
}