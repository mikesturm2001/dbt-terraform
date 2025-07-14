# Production Environment Configuration
dbtcloud_account_id = "67890"
dbtcloud_token      = "dbt_prod_token_here"
dbtcloud_host_url   = "https://prod.getdbt.com"

# These values should come from the central infrastructure outputs
project_id = "101"  # From central infrastructure output

team_name = "analytics-team"

# Production Jobs Configuration
# Optimized for reliability, performance, and business continuity
jobs = [
  # === CORE DATA MODELS ===
  {
    name           = "core-daily-refresh"
    description    = "Production daily refresh of core models - business critical"
    environment_id = "301"  # analytics-prod environment
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
    name           = "customer-analytics"
    description    = "Production customer analytics mart - business critical"
    environment_id = "301"  # analytics-prod environment
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
    name           = "revenue-reporting"
    description    = "Production revenue reporting - finance critical"
    environment_id = "301"  # analytics-prod environment
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
    name           = "critical-data-tests"
    description    = "Production critical data quality tests with alerting"
    environment_id = "301"  # analytics-prod environment
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
    name           = "data-monitoring"
    description    = "Production data monitoring with comprehensive reporting"
    environment_id = "301"  # analytics-prod environment
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
    name           = "daily-snapshots"
    description    = "Production snapshot refresh - historical data preservation"
    environment_id = "301"  # analytics-prod environment
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
    name           = "business-reporting"
    description    = "Critical business reporting for stakeholders"
    environment_id = "301"  # analytics-prod environment
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
    name           = "compliance-validation"
    description    = "Regulatory compliance and audit trail validation"
    environment_id = "301"  # analytics-prod environment
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

  # === EXAMPLE: MULTIPLE ENVIRONMENTS IN ONE FILE ===
  # Jobs that run in staging environment
  {
    name           = "staging-validation"
    description    = "Staging environment validation tests"
    environment_id = "202"  # analytics-staging environment
    execute_steps = [
      "dbt run --select tag:staging_tests",
      "dbt test --select tag:staging_tests"
    ]
    schedule_type  = "every_day"
    schedule_hours = [10]  # 10 AM - after prod jobs
    job_type       = "daily"
  },

  # Example of a job that could run in a different prod environment
  {
    name           = "special-reporting"
    description    = "Special reporting that runs in dedicated environment"
    environment_id = "302"  # analytics-prod-special environment (if exists)
    execute_steps = [
      "dbt run --select tag:special_reports",
      "dbt test --select tag:special_reports"
    ]
    schedule_type  = "every_day"
    schedule_hours = [14]  # 2 PM
    job_type       = "daily"
  }
]