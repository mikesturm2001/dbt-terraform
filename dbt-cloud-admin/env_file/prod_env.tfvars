# Production Environment Configuration
# This targets production environment (production branch)

dbtcloud_account_id = "67890"
dbtcloud_token      = "dbt_prod_token_here"
dbtcloud_host_url   = "https://prod.getdbt.com"

project_name        = "prod-terraform-project"

repository_url      = "https://github.com/your-org/your-dbt-project.git"
repository_branch   = "main"

# Multiple Environments Configuration
environments = {
  staging = {
    name                = "terraform-staging"
    type               = "development"
    dbt_version        = "1.7.0-latest"
    use_custom_branch  = false
    custom_branch      = "main"
    purpose            = "staging"
    allow_jobs         = true
    job_types          = ["daily"]
    
    snowflake_account   = "xyz789.us-west-2"
    snowflake_database  = "PROD_STAGING_DB"
    snowflake_warehouse = "PROD_STAGING_WH"
    snowflake_role      = "PROD_STAGING_ROLE"
    snowflake_username  = "prod_staging_user"
    snowflake_password  = "prod_staging_password_here"
  }
  
  prod = {
    name                = "terraform-prod"
    type               = "deployment"
    dbt_version        = "1.7.0-latest"
    use_custom_branch  = false
    custom_branch      = "main"
    deployment_type     = "production"
    purpose            = "production"
    allow_jobs         = true
    job_types          = ["daily"]
    
    snowflake_account   = "xyz789.us-west-2"
    snowflake_database  = "PROD_DB"
    snowflake_warehouse = "PROD_WH"
    snowflake_role      = "PROD_ROLE"
    snowflake_username  = "prod_user"
    snowflake_password  = "prod_password_here"
  }
  
  dr = {
    name                = "terraform-dr"
    type               = "deployment"
    dbt_version        = "1.7.0-latest"
    use_custom_branch  = false
    custom_branch      = "main"
    deployment_type     = "production"
    purpose            = "production"
    allow_jobs         = false
    job_types          = []
    
    snowflake_account   = "xyz789.us-central-1"
    snowflake_database  = "DR_DB"
    snowflake_warehouse = "DR_WH"
    snowflake_role      = "DR_ROLE"
    snowflake_username  = "dr_user"
    snowflake_password  = "dr_password_here"
  }
  
  cicd = {
    name                = "terraform-prod-cicd"
    type               = "development"
    dbt_version        = "1.7.0-latest"
    use_custom_branch  = true
    custom_branch      = "release/*"
    purpose            = "cicd"
    allow_jobs         = false
    job_types          = []
    
    snowflake_account   = "xyz789.us-west-2"
    snowflake_database  = "PROD_CICD_DB"
    snowflake_warehouse = "PROD_CICD_WH"
    snowflake_role      = "PROD_CICD_ROLE"
    snowflake_username  = "prod_cicd_user"
    snowflake_password  = "prod_cicd_password_here"
  }
}