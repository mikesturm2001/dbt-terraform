# Test Environment Configuration for Marketing Analytics Team
dbtcloud_account_id = "12345"
dbtcloud_token      = "your_dbt_cloud_api_token"
dbtcloud_host_url   = "https://cloud.getdbt.com"

# Marketing project ID from platform team
project_id = "102"

# Marketing staging environment from platform team
# From dbt-cloud-admin output: marketing_environments.staging.environment_id
environment_id = "202"

team_name = "marketing-team"

# Test Environment Jobs - Focused on validation and testing
jobs = [
  # === CORE VALIDATION ===
  {
    name          = "attribution-validation"
    description   = "Validation of marketing attribution models in test environment"
    execute_steps = [
      "dbt deps",
      "dbt run --select tag:attribution",
      "dbt test --select tag:attribution",
      "dbt test --select tag:business_logic"
    ]
    schedule_type  = "every_day"
    schedule_hours = [7]  # 7 AM
    job_type       = "daily"
    threads        = 4
    generate_docs  = true
  },
  
  {
    name          = "campaign-testing"
    description   = "Campaign performance model testing"
    execute_steps = [
      "dbt run --select tag:campaigns",
      "dbt test --select tag:campaigns",
      "dbt test --select tag:campaign_validation"
    ]
    schedule_type  = "every_day"
    schedule_hours = [8]  # 8 AM
    job_type       = "daily"
    threads        = 4
  },
  
  # === INTEGRATION TESTING ===
  {
    name          = "ad-platform-integration-test"
    description   = "Test ad platform integrations and data quality"
    execute_steps = [
      "dbt run --select tag:ad_platforms",
      "dbt test --select tag:ad_platforms",
      "dbt test --select tag:integration_tests"
    ]
    schedule_type  = "every_day"
    schedule_hours = [9]  # 9 AM
    job_type       = "daily"
    threads        = 2
  },
  
  # === BUSINESS LOGIC VALIDATION ===
  {
    name          = "ltv-model-validation"
    description   = "Customer LTV model validation in test environment"
    execute_steps = [
      "dbt run --select tag:ltv_models",
      "dbt test --select tag:ltv_models",
      "dbt test --select tag:ltv_validation"
    ]
    schedule_type  = "every_day"
    schedule_hours = [10]  # 10 AM
    job_type       = "daily"
    threads        = 3
  },
  
  # === EXECUTIVE DASHBOARD TESTING ===
  {
    name          = "executive-dashboard-test"
    description   = "Test executive dashboard data and calculations"
    execute_steps = [
      "dbt run --select tag:executive_reporting",
      "dbt test --select tag:executive_reporting",
      "dbt test --select tag:kpi_validation"
    ]
    schedule_type  = "every_day"
    schedule_hours = [11]  # 11 AM
    job_type       = "daily"
    threads        = 2
  },
  
  # === COMPREHENSIVE DATA QUALITY ===
  {
    name          = "marketing-comprehensive-tests"
    description   = "Comprehensive marketing data quality tests"
    execute_steps = [
      "dbt test --select tag:marketing_quality",
      "dbt test --select tag:attribution_tests",
      "dbt test --select tag:data_integrity"
    ]
    schedule_type  = "every_day"
    schedule_hours = [20]  # 8 PM
    job_type       = "daily"
    threads        = 3
  }
]