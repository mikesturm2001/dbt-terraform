# ===============================================
# dbt Cloud Admin Configuration Example
# ===============================================

# dbt Cloud Account Configuration
dbtcloud_account_id = "12345"
dbtcloud_token      = "your_dbt_cloud_api_token_here"
dbtcloud_host_url   = "https://cloud.getdbt.com"

# ===============================================
# GIT REPOSITORY URLS
# ===============================================
analytics_repository_url = "https://github.com/company/dbt-analytics-models"
marketing_repository_url = "https://github.com/company/dbt-marketing-models"
finance_repository_url   = "https://github.com/company/dbt-finance-models"
platform_repository_url  = "https://github.com/company/dbt-platform-core"

# ===============================================
# ENVIRONMENT CONFIGURATION
# ===============================================
environments = {
  # Development Environment
  dev = {
    name                = "development"
    type               = "development"
    dbt_version        = "1.7.0-latest"
    use_custom_branch  = true
    custom_branch      = ""  # Allows any branch
    deployment_type    = "development"
    purpose            = "general"
    allow_jobs         = true
    job_types          = ["daily", "hourly", "on-demand"]
    
    # Snowflake configuration
    snowflake_account   = "company.snowflakecomputing.com"
    snowflake_warehouse = "COMPUTE_WH"
    snowflake_username  = "dbt_service_user"
    snowflake_password  = "your_snowflake_password"
    
    # Team-specific databases
    analytics_database = "ANALYTICS_DEV"
    analytics_role     = "ANALYTICS_DEV_ROLE"
    
    marketing_database = "MARKETING_DEV"
    marketing_role     = "MARKETING_DEV_ROLE"
    
    finance_database   = "FINANCE_DEV"
    finance_role       = "FINANCE_DEV_ROLE"
    
    platform_database  = "PLATFORM_DEV"
    platform_role      = "PLATFORM_DEV_ROLE"
  }
  
  # Staging/Test Environment
  staging = {
    name                = "staging"
    type               = "deployment"
    dbt_version        = "1.7.0-latest"
    use_custom_branch  = false
    custom_branch      = "main"
    deployment_type    = "staging"
    purpose            = "staging"
    allow_jobs         = true
    job_types          = ["daily", "on-demand"]
    
    # Snowflake configuration
    snowflake_account   = "company.snowflakecomputing.com"
    snowflake_warehouse = "COMPUTE_WH"
    snowflake_username  = "dbt_service_user"
    snowflake_password  = "your_snowflake_password"
    
    # Team-specific databases
    analytics_database = "ANALYTICS_STAGING"
    analytics_role     = "ANALYTICS_STAGING_ROLE"
    
    marketing_database = "MARKETING_STAGING"
    marketing_role     = "MARKETING_STAGING_ROLE"
    
    finance_database   = "FINANCE_STAGING"
    finance_role       = "FINANCE_STAGING_ROLE"
    
    platform_database  = "PLATFORM_STAGING"
    platform_role      = "PLATFORM_STAGING_ROLE"
  }
  
  # Production Environment
  prod = {
    name                = "production"
    type               = "deployment"
    dbt_version        = "1.7.0-latest"
    use_custom_branch  = false
    custom_branch      = "main"
    deployment_type    = "production"
    purpose            = "production"
    allow_jobs         = true
    job_types          = ["daily"]  # Only daily jobs in production
    
    # Snowflake configuration
    snowflake_account   = "company.snowflakecomputing.com"
    snowflake_warehouse = "COMPUTE_WH"
    snowflake_username  = "dbt_service_user"
    snowflake_password  = "your_snowflake_password"
    
    # Team-specific databases
    analytics_database = "ANALYTICS_PROD"
    analytics_role     = "ANALYTICS_PROD_ROLE"
    
    marketing_database = "MARKETING_PROD"
    marketing_role     = "MARKETING_PROD_ROLE"
    
    finance_database   = "FINANCE_PROD"
    finance_role       = "FINANCE_PROD_ROLE"
    
    platform_database  = "PLATFORM_PROD"
    platform_role      = "PLATFORM_PROD_ROLE"
  }
}

# ===============================================
# USER MANAGEMENT
# ===============================================

# Analytics Team Users
analytics_users = {
  sarah_chen = {
    email      = "sarah.chen@company.com"
    first_name = "Sarah"
    last_name  = "Chen"
    is_active  = true
  }
  mike_rodriguez = {
    email      = "mike.rodriguez@company.com"
    first_name = "Mike"
    last_name  = "Rodriguez"
    is_active  = true
  }
  jessica_park = {
    email      = "jessica.park@company.com"
    first_name = "Jessica"
    last_name  = "Park"
    is_active  = true
  }
  david_kim = {
    email      = "david.kim@company.com"
    first_name = "David"
    last_name  = "Kim"
    is_active  = true
  }
}

# Marketing Team Users
marketing_users = {
  jennifer_lopez = {
    email      = "jennifer.lopez@company.com"
    first_name = "Jennifer"
    last_name  = "Lopez"
    is_active  = true
  }
  alex_thompson = {
    email      = "alex.thompson@company.com"
    first_name = "Alex"
    last_name  = "Thompson"
    is_active  = true
  }
  maria_gonzalez = {
    email      = "maria.gonzalez@company.com"
    first_name = "Maria"
    last_name  = "Gonzalez"
    is_active  = true
  }
}

# Finance Team Users
finance_users = {
  robert_johnson = {
    email      = "robert.johnson@company.com"
    first_name = "Robert"
    last_name  = "Johnson"
    is_active  = true
  }
  lisa_brown = {
    email      = "lisa.brown@company.com"
    first_name = "Lisa"
    last_name  = "Brown"
    is_active  = true
  }
  chris_wilson = {
    email      = "chris.wilson@company.com"
    first_name = "Chris"
    last_name  = "Wilson"
    is_active  = true
  }
}

# Platform Team Users
platform_users = {
  admin_user = {
    email      = "admin@company.com"
    first_name = "Platform"
    last_name  = "Admin"
    is_active  = true
  }
  devops_engineer = {
    email      = "devops@company.com"
    first_name = "DevOps"
    last_name  = "Engineer"
    is_active  = true
  }
  data_engineer = {
    email      = "data.engineer@company.com"
    first_name = "Data"
    last_name  = "Engineer"
    is_active  = true
  }
}