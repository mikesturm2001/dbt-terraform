# Test Environment Configuration
# This targets shared dev environment (master branch)

dbtcloud_account_id = "12345"
dbtcloud_token      = "dbt_test_token_here"
dbtcloud_host_url   = "https://dev.getdbt.com"

project_name        = "test-terraform-project"

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
    snowflake_database  = "TEST_DEV_DB"
    snowflake_warehouse = "TEST_DEV_WH"
    snowflake_role      = "TEST_DEV_ROLE"
    snowflake_username  = "test_dev_user"
    snowflake_password  = "test_dev_password_here"
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
    snowflake_database  = "TEST_STAGING_DB"
    snowflake_warehouse = "TEST_STAGING_WH"
    snowflake_role      = "TEST_STAGING_ROLE"
    snowflake_username  = "test_staging_user"
    snowflake_password  = "test_staging_password_here"
  }
  
  qa = {
    name                = "terraform-qa"
    type               = "development"
    dbt_version        = "1.7.0-latest"
    use_custom_branch  = false
    custom_branch      = "main"
    purpose            = "qa"
    allow_jobs         = true
    job_types          = ["daily"]
    
    snowflake_account   = "abc123.us-east-1"
    snowflake_database  = "QA_DB"
    snowflake_warehouse = "QA_WH"
    snowflake_role      = "QA_ROLE"
    snowflake_username  = "qa_user"
    snowflake_password  = "qa_password_here"
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
    snowflake_database  = "TEST_CICD_DB"
    snowflake_warehouse = "TEST_CICD_WH"
    snowflake_role      = "TEST_CICD_ROLE"
    snowflake_username  = "test_cicd_user"
    snowflake_password  = "test_cicd_password_here"
  }
}