# Production Environment Configuration for Marketing Analytics Team
dbtcloud_account_id = "12345"
dbtcloud_token      = "your_dbt_cloud_api_token"
dbtcloud_host_url   = "https://cloud.getdbt.com"

# Marketing project ID from platform team
project_id = "102"

# Marketing production environment from platform team
# From dbt-cloud-admin output: marketing_environments.prod.environment_id
environment_id = "302"

team_name = "marketing-team"

# Production Jobs - Mission-critical marketing analytics
jobs = [
  # === CORE MARKETING MODELS ===
  {
    name          = "attribution-production"
    description   = "Production marketing attribution models"
    execute_steps = [
      "dbt deps",
      "dbt run --select tag:attribution",
      "dbt test --select tag:attribution",
      "dbt test --select tag:critical"
    ]
    schedule_type  = "every_day"
    schedule_hours = [5]  # 5 AM - very early
    job_type       = "daily"
    threads        = 6
    generate_docs  = true
  },
  
  {
    name          = "campaign-performance-production"
    description   = "Production campaign performance tracking"
    execute_steps = [
      "dbt run --select tag:campaigns",
      "dbt test --select tag:campaigns",
      "dbt test --select tag:critical"
    ]
    schedule_type  = "every_day"
    schedule_hours = [6]  # 6 AM - after attribution
    job_type       = "daily"
    threads        = 6
    generate_docs  = true
  },
  
  # === CUSTOMER ANALYTICS ===
  {
    name          = "customer-ltv-production"
    description   = "Production customer lifetime value models"
    execute_steps = [
      "dbt run --select tag:ltv_models",
      "dbt test --select tag:ltv_models",
      "dbt test --select tag:critical"
    ]
    schedule_type  = "every_day"
    schedule_hours = [7]  # 7 AM
    job_type       = "daily"
    threads        = 4
    generate_docs  = true
  },
  
  # === EXECUTIVE REPORTING ===
  {
    name          = "executive-dashboard-production"
    description   = "Production executive marketing dashboard"
    execute_steps = [
      "dbt run --select tag:executive_reporting",
      "dbt test --select tag:executive_reporting",
      "dbt test --select tag:critical"
    ]
    schedule_type  = "every_day"
    schedule_hours = [8]  # 8 AM - after LTV models
    job_type       = "daily"
    threads        = 4
    generate_docs  = true
  },
  
  # === CRITICAL DATA VALIDATION ===
  {
    name          = "marketing-critical-tests"
    description   = "Critical marketing data quality validation"
    execute_steps = [
      "dbt test --select tag:critical",
      "dbt test --select tag:marketing_quality"
    ]
    schedule_type  = "every_day"
    schedule_hours = [9, 21]  # 9 AM and 9 PM
    job_type       = "daily"
    threads        = 2
  }
]