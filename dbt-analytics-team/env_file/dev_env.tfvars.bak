# Development Environment Configuration
dbtcloud_account_id = "12345"
dbtcloud_token      = "your_dbt_cloud_api_token"
dbtcloud_host_url   = "https://dev.getdbt.com"

# These values should come from the central infrastructure outputs
project_id = "101"  # From central infrastructure output

team_name = "analytics-team"

# Development Jobs Configuration
# Optimized for fast iteration and testing
jobs = [
  # === CORE DATA MODELS ===
  {
    name           = "core-daily-refresh"
    description    = "Daily refresh of core foundational models - dev environment"
    environment_id = "999"  # shared terraform-dev environment
    execute_steps = [
      "dbt deps",
      "dbt run --select tag:core --defer",
      "dbt test --select tag:core"
    ]
    schedule_type  = "every_day"
    schedule_hours = [9]  # 9 AM - after morning standup
    job_type       = "daily"
  },
  {
    name          = "core-incremental-sync"
    description   = "Incremental updates for real-time data - dev environment"
    execute_steps = [
      "dbt run --select tag:incremental --defer",
      "dbt test --select tag:incremental"
    ]
    schedule_type  = "custom"
    schedule_hours = [10, 14, 16]  # 10 AM, 2 PM, 4 PM
    schedule_days  = [1, 2, 3, 4, 5]  # Weekdays only
    job_type       = "hourly"
  },

  # === DATA MARTS ===
  {
    name          = "customer-analytics"
    description   = "Customer analytics data mart refresh - dev environment"
    execute_steps = [
      "dbt run --select tag:customer_analytics --defer",
      "dbt test --select tag:customer_analytics"
    ]
    schedule_type  = "every_day" 
    schedule_hours = [10]  # After core models
    job_type       = "daily"
  },
  {
    name          = "revenue-reporting"
    description   = "Revenue and financial reporting data mart - dev environment"
    execute_steps = [
      "dbt run --select tag:revenue --defer",
      "dbt test --select tag:revenue"
    ]
    schedule_type  = "every_day"
    schedule_hours = [11]  # After customer analytics
    job_type       = "daily"
  },

  # === DATA QUALITY ===
  {
    name          = "critical-data-tests"
    description   = "Critical data quality validation - dev environment"
    execute_steps = [
      "dbt test --select tag:critical"
    ]
    schedule_type  = "every_day"
    schedule_hours = [20]  # 8 PM - end of day
    job_type       = "daily"
  },
  {
    name          = "data-monitoring"
    description   = "Data monitoring and profiling - dev environment"
    execute_steps = [
      "dbt test --select tag:monitoring",
      "python data_profiling.py --env=dev"
    ]
    schedule_type  = "every_day"
    schedule_hours = []  # On-demand only for dev
    job_type       = "on-demand"
  },

  # === OPERATIONAL ===
  {
    name          = "daily-snapshots"
    description   = "Historical data snapshots - dev environment"
    execute_steps = [
      "dbt snapshot --select tag:daily_snapshots"
    ]
    schedule_type  = "every_day"
    schedule_hours = [12]  # Noon - mid-day
    job_type       = "daily"
  },

  # === DEVELOPMENT SPECIFIC ===
  {
    name          = "feature-testing"
    description   = "On-demand testing for feature development"
    execute_steps = [
      "dbt deps",
      "dbt compile",
      "dbt test --select tag:feature"
    ]
    schedule_type  = "every_day"
    schedule_hours = []  # Manual trigger only
    job_type       = "on-demand"
  },
  {
    name          = "data-exploration"
    description   = "Data exploration and profiling"
    execute_steps = [
      "dbt deps",
      "dbt run --select tag:exploration",
      "dbt test --select tag:data_quality"
    ]
    schedule_type  = "every_day"
    schedule_hours = [17]  # 5 PM - end of work day
    job_type       = "daily"
  }
]