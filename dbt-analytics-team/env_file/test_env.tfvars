# Test Environment Configuration
dbtcloud_account_id = "12345"
dbtcloud_token      = "dbt_test_token_here"
dbtcloud_host_url   = "https://dev.getdbt.com"

# These values should come from the central infrastructure outputs
project_id = "101"  # From central infrastructure output

# Target dbt Cloud Environment (where jobs will be deployed)
environment_id = "202"  # terraform-staging environment ID

team_name = "analytics-team"

# Test Environment Jobs Configuration
# Focused on validation and pre-production testing
jobs = [
  # === CORE DATA MODELS ===
  {
    name          = "core-daily-refresh"
    description   = "Daily refresh of core foundational models - test environment"
    execute_steps = [
      "dbt deps",
      "dbt seed --full-refresh",
      "dbt run --select tag:core",
      "dbt test --select tag:core",
      "dbt test --select tag:data_quality"
    ]
    schedule_type  = "every_day"
    schedule_hours = [7]  # 7 AM - earlier for testing
    job_type       = "daily"
  },

  # === DATA MARTS ===
  {
    name          = "customer-analytics"
    description   = "Customer analytics data mart refresh - test environment"
    execute_steps = [
      "dbt run --select tag:customer_analytics",
      "dbt test --select tag:customer_analytics",
      "dbt test --select tag:business_logic"
    ]
    schedule_type  = "every_day" 
    schedule_hours = [8]  # After core models
    job_type       = "daily"
  },
  {
    name          = "revenue-reporting"
    description   = "Revenue and financial reporting data mart - test environment"
    execute_steps = [
      "dbt run --select tag:revenue",
      "dbt test --select tag:revenue", 
      "dbt test --select tag:financial_accuracy"
    ]
    schedule_type  = "every_day"
    schedule_hours = [9]  # After customer analytics
    job_type       = "daily"
  },

  # === DATA QUALITY ===
  {
    name          = "critical-data-tests"
    description   = "Critical data quality validation - test environment"
    execute_steps = [
      "dbt test --select tag:critical",
      "dbt test --select tag:data_quality"
    ]
    schedule_type  = "every_day"
    schedule_hours = [22]  # 10 PM - after all builds
    job_type       = "daily"
  },
  {
    name          = "data-monitoring"
    description   = "Data monitoring and profiling - test environment"
    execute_steps = [
      "dbt test --select tag:monitoring",
      "python data_profiling.py --env=test"
    ]
    schedule_type  = "every_day"
    schedule_hours = [23]  # 11 PM - end of day summary
    job_type       = "daily"
  },

  # === OPERATIONAL ===
  {
    name          = "daily-snapshots"
    description   = "Historical data snapshots - test environment"
    execute_steps = [
      "dbt snapshot --select tag:daily_snapshots",
      "dbt test --select tag:snapshot_tests"
    ]
    schedule_type  = "every_day"
    schedule_hours = [6]  # 6 AM - early morning snapshot
    job_type       = "daily"
  },

  # === TEST SPECIFIC ===
  {
    name          = "staging-validation"
    description   = "Pre-production validation tests"
    execute_steps = [
      "dbt deps",
      "dbt test --select tag:critical", 
      "dbt test --select tag:data_quality",
      "dbt test --select tag:business_logic"
    ]
    schedule_type  = "every_day"
    schedule_hours = [23]  # 11 PM - comprehensive end-of-day validation
    job_type       = "daily"
  },
  {
    name          = "release-testing"
    description   = "On-demand release testing"
    execute_steps = [
      "dbt deps",
      "dbt compile",
      "dbt run --full-refresh",
      "dbt test"
    ]
    schedule_type  = "every_day"
    schedule_hours = []  # Manual trigger only
    job_type       = "on-demand"
  },

  # === SKIPPED JOBS ===
  # This job will be SKIPPED because staging environment doesn't allow hourly jobs
  {
    name          = "hourly-sync"
    description   = "This job will be SKIPPED - staging doesn't allow hourly jobs"
    execute_steps = [
      "dbt run --select tag:incremental"
    ]
    schedule_type  = "custom"
    schedule_hours = [9, 12, 15, 18]
    schedule_days  = [1, 2, 3, 4, 5]
    job_type       = "hourly"  # Will be filtered out!
  }
]