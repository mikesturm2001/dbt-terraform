# Development Environment Configuration for Marketing Analytics Team
dbtcloud_account_id = "12345"
dbtcloud_token      = "your_dbt_cloud_api_token"
dbtcloud_host_url   = "https://cloud.getdbt.com"

# These values come from the platform team's terraform outputs
# Marketing project ID from dbt-cloud-admin output: marketing_project.project_id
project_id = "102"  # Marketing project ID

team_name = "marketing-team"

# Marketing Analytics Jobs Configuration
# Focused on customer acquisition, campaign performance, and marketing attribution
jobs = [
  # === MARKETING ATTRIBUTION ===
  {
    name           = "attribution-daily-refresh"
    description    = "Daily refresh of marketing attribution models"
    environment_id = "999"  # shared terraform-dev environment
    execute_steps = [
      "dbt deps",
      "dbt run --select tag:attribution",
      "dbt test --select tag:attribution"
    ]
    schedule_type  = "every_day"
    schedule_hours = [8]  # 8 AM - after customer data updates
    job_type       = "daily"
    threads        = 4
    generate_docs  = true
  },
  
  # === CAMPAIGN PERFORMANCE ===
  {
    name           = "campaign-performance"
    description    = "Campaign performance tracking and reporting"
    environment_id = "999"  # shared terraform-dev environment
    execute_steps = [
      "dbt run --select tag:campaigns",
      "dbt test --select tag:campaigns",
      "dbt run --select tag:campaign_metrics"
    ]
    schedule_type  = "every_day"
    schedule_hours = [9]  # 9 AM - after attribution models
    job_type       = "daily"
    threads        = 6
    generate_docs  = true
  },
  
  # === CUSTOMER ACQUISITION ===
  {
    name           = "customer-acquisition-funnel"
    description    = "Customer acquisition funnel analysis"
    environment_id = "999"  # shared terraform-dev environment
    execute_steps = [
      "dbt run --select tag:acquisition",
      "dbt test --select tag:acquisition",
      "dbt run --select tag:funnel_analysis"
    ]
    schedule_type  = "every_day"
    schedule_hours = [10]  # 10 AM - after campaign performance
    job_type       = "daily"
    threads        = 4
  },
  
  # === AD PLATFORM INTEGRATION ===
  {
    name           = "ad-platform-sync"
    description    = "Sync data from Facebook, Google, LinkedIn ad platforms"
    environment_id = "999"  # shared terraform-dev environment
    execute_steps = [
      "dbt run --select tag:ad_platforms",
      "dbt test --select tag:ad_platforms"
    ]
    schedule_type  = "custom"
    schedule_hours = [6, 12, 18]  # 6 AM, noon, 6 PM
    schedule_days  = [1, 2, 3, 4, 5, 6, 7]  # Every day
    job_type       = "hourly"
    threads        = 2
  },
  
  # === EMAIL & MARKETING AUTOMATION ===
  {
    name           = "email-marketing-metrics"
    description    = "Email marketing and automation performance metrics"
    environment_id = "999"  # shared terraform-dev environment
    execute_steps = [
      "dbt run --select tag:email_marketing",
      "dbt test --select tag:email_marketing",
      "dbt run --select tag:automation_flows"
    ]
    schedule_type  = "every_day"
    schedule_hours = [11]  # 11 AM
    job_type       = "daily"
    threads        = 3
  },
  
  # === CUSTOMER LIFETIME VALUE ===
  {
    name           = "customer-ltv-modeling"
    description    = "Customer lifetime value modeling and segmentation"
    environment_id = "999"  # shared terraform-dev environment
    execute_steps = [
      "dbt run --select tag:ltv_models",
      "dbt test --select tag:ltv_models",
      "dbt run --select tag:customer_segments"
    ]
    schedule_type  = "every_day"
    schedule_hours = [12]  # Noon - after acquisition funnel
    job_type       = "daily"
    threads        = 4
    generate_docs  = true
  },
  
  # === MARKETING DATA QUALITY ===
  {
    name           = "marketing-data-quality"
    description    = "Marketing data quality validation and monitoring"
    environment_id = "999"  # shared terraform-dev environment
    execute_steps = [
      "dbt test --select tag:marketing_quality",
      "dbt test --select tag:attribution_tests"
    ]
    schedule_type  = "every_day"
    schedule_hours = [21]  # 9 PM - end of day validation
    job_type       = "daily"
    threads        = 2
  },
  
  # === DEVELOPMENT SPECIFIC ===
  {
    name           = "marketing-model-testing"
    description    = "On-demand testing for marketing model development"
    environment_id = "999"  # shared terraform-dev environment
    execute_steps = [
      "dbt deps",
      "dbt compile",
      "dbt test --select tag:development"
    ]
    schedule_type  = "every_day"
    schedule_hours = []  # Manual trigger only
    job_type       = "on-demand"
    threads        = 2
  },
  
  # === EXECUTIVE REPORTING ===
  {
    name           = "marketing-executive-dashboard"
    description    = "Executive marketing dashboard and KPI refresh"
    environment_id = "999"  # shared terraform-dev environment
    execute_steps = [
      "dbt run --select tag:executive_reporting",
      "dbt test --select tag:executive_reporting",
      "dbt run --select tag:marketing_kpis"
    ]
    schedule_type  = "every_day"
    schedule_hours = [13]  # 1 PM - after LTV modeling
    job_type       = "daily"
    threads        = 3
    generate_docs  = true
  }
]