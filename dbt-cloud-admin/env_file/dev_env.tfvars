# Development Environment Configuration
# This targets individual dev environments (branch/*)

dbtcloud_account_id = "12345"
dbtcloud_token      = "dbt_dev_token_here"
dbtcloud_host_url   = "https://dev.getdbt.com"

project_name        = "dev-terraform-project"

repository_url      = "https://github.com/your-org/your-dbt-project.git"
repository_branch   = "main"

# Multiple Environments Configuration
environments = {
  dev = {
    name                = "terraform-dev"
    type               = "development"
    dbt_version        = "1.7.0-latest"
    use_custom_branch  = true
    custom_branch      = "develop"
    purpose            = "general"
    allow_jobs         = true
    job_types          = ["daily", "hourly", "on-demand"]
    
    snowflake_account   = "abc123.us-east-1"
    snowflake_database  = "DEV_DB"
    snowflake_warehouse = "DEV_WH"
    snowflake_role      = "DEV_ROLE"
    snowflake_username  = "dev_user"
    snowflake_password  = "dev_password_here"
  }
  
  staging = {
    name                = "terraform-staging"
    type               = "development"
    dbt_version        = "1.7.0-latest"
    use_custom_branch  = false
    custom_branch      = "main"
    purpose            = "staging"
    allow_jobs         = true
    job_types          = ["daily", "on-demand"]
    
    snowflake_account   = "abc123.us-east-1"
    snowflake_database  = "STAGING_DB"
    snowflake_warehouse = "STAGING_WH"
    snowflake_role      = "STAGING_ROLE"
    snowflake_username  = "staging_user"
    snowflake_password  = "staging_password_here"
  }
  
  cicd = {
    name                = "terraform-cicd"
    type               = "development"
    dbt_version        = "1.7.0-latest"
    use_custom_branch  = true
    custom_branch      = "feature/*"
    purpose            = "cicd"
    allow_jobs         = false
    job_types          = []
    
    snowflake_account   = "abc123.us-east-1"
    snowflake_database  = "CICD_DB"
    snowflake_warehouse = "CICD_WH"
    snowflake_role      = "CICD_ROLE"
    snowflake_username  = "cicd_user"
    snowflake_password  = "cicd_password_here"
  }
}