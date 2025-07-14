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
  description = "dbt Cloud Host URL (e.g., https://dev.getdbt.com or https://prod.getdbt.com)"
  default     = "https://cloud.getdbt.com"
}

# ===============================================
# GIT REPOSITORY CONFIGURATION
# ===============================================

variable "analytics_repository_url" {
  type        = string
  description = "Git repository URL for Analytics Team dbt project"
  default     = ""
}

variable "marketing_repository_url" {
  type        = string
  description = "Git repository URL for Marketing Team dbt project"
  default     = ""
}

variable "finance_repository_url" {
  type        = string
  description = "Git repository URL for Finance Team dbt project"
  default     = ""
}

variable "platform_repository_url" {
  type        = string
  description = "Git repository URL for Platform Team dbt project"
  default     = ""
}

# Multiple Environments Configuration
variable "environments" {
  type = map(object({
    name                = string
    type               = string
    dbt_version        = optional(string, "1.7.0-latest")
    use_custom_branch  = optional(bool, false)
    custom_branch      = optional(string, "main")
    deployment_type    = optional(string, null)
    
    # Environment purpose and job control
    purpose            = optional(string, "general")
    allow_jobs         = optional(bool, true)
    job_types          = optional(list(string), ["daily", "hourly", "on-demand"])
    
    # Snowflake connection details per environment
    snowflake_account   = string
    snowflake_warehouse = string
    snowflake_username  = string
    snowflake_password  = string
    
    # Team-specific databases and roles
    analytics_database  = string
    analytics_role      = optional(string, "ANALYTICS_ROLE")
    
    marketing_database  = string
    marketing_role      = optional(string, "MARKETING_ROLE")
    
    finance_database    = string
    finance_role        = optional(string, "FINANCE_ROLE")
    
    platform_database   = string
    platform_role       = optional(string, "PLATFORM_ROLE")
  }))
  description = "Map of environments to create with their specific configurations"
  
  validation {
    condition = alltrue([
      for env in values(var.environments) : contains(["deployment", "development"], env.type)
    ])
    error_message = "All environment types must be either 'deployment' or 'development'."
  }
  
  validation {
    condition = alltrue([
      for env in values(var.environments) : contains(["general", "testing", "cicd", "production", "staging", "qa"], env.purpose)
    ])
    error_message = "Environment purpose must be one of: general, testing, cicd, production, staging, qa."
  }
}

# ===============================================
# USER MANAGEMENT
# ===============================================

variable "analytics_users" {
  type = map(object({
    email      = string
    first_name = string
    last_name  = string
    is_active  = optional(bool, true)
  }))
  description = "Analytics team user accounts"
  default     = {}
}

variable "marketing_users" {
  type = map(object({
    email      = string
    first_name = string
    last_name  = string
    is_active  = optional(bool, true)
  }))
  description = "Marketing team user accounts"
  default     = {}
}

variable "finance_users" {
  type = map(object({
    email      = string
    first_name = string
    last_name  = string
    is_active  = optional(bool, true)
  }))
  description = "Finance team user accounts"
  default     = {}
}

variable "platform_users" {
  type = map(object({
    email      = string
    first_name = string
    last_name  = string
    is_active  = optional(bool, true)
  }))
  description = "Platform team user accounts"
  default     = {}
}