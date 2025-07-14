# Production Environment Configuration
dbtcloud_account_id = "67890"
dbtcloud_token      = "dbt_prod_token_here"
dbtcloud_host_url   = "https://prod.getdbt.com"

# These values should come from the central infrastructure outputs
project_id = "101"  # From central infrastructure output

# Target dbt Cloud Environment (where jobs will be deployed)
environment_id = "302"  # terraform-prod environment ID

team_name = "analytics-team"

# Production Jobs Configuration
# Optimized for reliability, performance, and business continuity
jobs = [
  # === CORE DATA MODELS ===
  {
    name          = "core-daily-refresh"
    description   = "Production daily refresh of core models - business critical"
    execute_steps = [
      "dbt deps",
      "dbt seed",
      "dbt run --select tag:core",
      "dbt test --select tag:core",
      "dbt test --select tag:critical",
      "dbt docs generate"
    ]
    schedule_type  = "every_day"
    schedule_hours = [5]  # 5 AM - early for production
    job_type       = "daily"
  },

  # === DATA MARTS ===
  {
    name          = "customer-analytics"
    description   = "Production customer analytics mart - business critical"
    execute_steps = [
      "dbt run --select tag:customer_analytics",
      "dbt test --select tag:customer_analytics",
      "dbt test --select tag:business_logic",
      "dbt test --select tag:sla_critical"
    ]
    schedule_type  = "every_day" 
    schedule_hours = [6]  # 6 AM - after core models complete
    job_type       = "daily"
  },
  {
    name          = "revenue-reporting"
    description   = "Production revenue reporting - finance critical"
    execute_steps = [
      "dbt run --select tag:revenue",
      "dbt test --select tag:revenue",
      "dbt test --select tag:financial_accuracy",
      "dbt test --select tag:sox_compliance"
    ]
    schedule_type  = "every_day"
    schedule_hours = [7]  # 7 AM - after customer analytics
    job_type       = "daily"
  },

  # === DATA QUALITY ===
  {
    name          = "critical-data-tests"
    description   = "Production critical data quality tests with alerting"
    execute_steps = [
      "dbt test --select tag:critical",
      "dbt test --select tag:data_quality",
      "dbt test --select tag:sla_critical",
      "python send_alerts.py"
    ]
    schedule_type  = "every_day"
    schedule_hours = [8, 20]  # 8 AM and 8 PM - twice daily
    job_type       = "daily"
  },
  {
    name          = "data-monitoring"
    description   = "Production data monitoring with comprehensive reporting"
    execute_steps = [
      "dbt test --select tag:monitoring",
      "python data_profiling.py --env=prod",
      "python generate_monitoring_report.py",
      "python send_daily_summary.py"
    ]
    schedule_type  = "every_day"
    schedule_hours = [23]  # 11 PM - end of day comprehensive summary
    job_type       = "daily"
  },

  # === OPERATIONAL ===
  {
    name          = "daily-snapshots"
    description   = "Production snapshot refresh - historical data preservation"
    execute_steps = [
      "dbt snapshot --select tag:daily_snapshots",
      "dbt test --select tag:snapshot_tests",
      "python backup_snapshots.py --env=prod"
    ]
    schedule_type  = "every_day"
    schedule_hours = [4]  # 4 AM - very early morning
    job_type       = "daily"
  },

  # === PRODUCTION SPECIFIC ===
  {
    name          = "business-reporting"
    description   = "Critical business reporting for stakeholders"
    execute_steps = [
      "dbt run --select tag:business_reports",
      "dbt test --select tag:business_reports",
      "python generate_executive_reports.py",
      "python send_stakeholder_reports.py"
    ]
    schedule_type  = "every_day"
    schedule_hours = [8]  # 8 AM - ready for business hours
    job_type       = "daily"
  },
  {
    name          = "compliance-validation"
    description   = "Regulatory compliance and audit trail validation"
    execute_steps = [
      "dbt test --select tag:compliance",
      "dbt test --select tag:audit_trail",
      "python compliance_report.py --env=prod",
      "python archive_compliance_data.py"
    ]
    schedule_type  = "every_day"
    schedule_hours = [22]  # 10 PM - end of business day
    job_type       = "daily"
  },

  # === JOBS THAT WILL BE SKIPPED ===
  # These jobs will be SKIPPED because prod only allows daily jobs
  {
    name          = "hourly-updates"
    description   = "This job will be SKIPPED - prod only allows daily jobs"
    execute_steps = [
      "dbt run --select tag:incremental"
    ]
    schedule_type  = "custom"
    schedule_hours = [6, 12, 18]
    schedule_days  = [1, 2, 3, 4, 5, 6, 7]
    job_type       = "hourly"  # Will be filtered out!
  },
  {
    name          = "manual-intervention"
    description   = "This job will be SKIPPED - prod doesn't allow on-demand jobs"
    execute_steps = [
      "dbt run --full-refresh"
    ]
    schedule_type  = "every_day"
    schedule_hours = []
    job_type       = "on-demand"  # Will be filtered out!
  }
]