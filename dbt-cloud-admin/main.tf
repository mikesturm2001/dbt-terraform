# ===============================================
# PROJECTS - Multiple teams/projects
# ===============================================

# Analytics Team Project
resource "dbtcloud_project" "analytics" {
  name = "Analytics Team"
}

# Marketing Team Project  
resource "dbtcloud_project" "marketing" {
  name = "Marketing Analytics"
}

# Finance Team Project
resource "dbtcloud_project" "finance" {
  name = "Finance Reporting"
}

# Data Platform Project (shared/core)
resource "dbtcloud_project" "platform" {
  name = "Data Platform Core"
}

# ===============================================
# GIT REPOSITORIES
# ===============================================

# Analytics Team Repository
resource "dbtcloud_repository" "analytics" {
  count              = var.analytics_repository_url != "" ? 1 : 0
  project_id         = dbtcloud_project.analytics.id
  remote_url         = var.analytics_repository_url
  git_clone_strategy = "github_app"
}

# Marketing Team Repository
resource "dbtcloud_repository" "marketing" {
  count              = var.marketing_repository_url != "" ? 1 : 0
  project_id         = dbtcloud_project.marketing.id
  remote_url         = var.marketing_repository_url
  git_clone_strategy = "github_app"
}

# Finance Team Repository
resource "dbtcloud_repository" "finance" {
  count              = var.finance_repository_url != "" ? 1 : 0
  project_id         = dbtcloud_project.finance.id
  remote_url         = var.finance_repository_url
  git_clone_strategy = "github_app"
}

# Platform Team Repository
resource "dbtcloud_repository" "platform" {
  count              = var.platform_repository_url != "" ? 1 : 0
  project_id         = dbtcloud_project.platform.id
  remote_url         = var.platform_repository_url
  git_clone_strategy = "github_app"
}

# ===============================================
# SNOWFLAKE CONNECTIONS - Per Project Per Environment
# ===============================================

# Analytics Team Connections
resource "dbtcloud_snowflake_connection" "analytics_environments" {
  for_each = var.environments
  
  project_id = dbtcloud_project.analytics.id
  name       = "analytics-${each.key}-connection"
  type       = "snowflake"
  
  account    = each.value.snowflake_account
  database   = each.value.analytics_database
  warehouse  = each.value.snowflake_warehouse
  role       = each.value.analytics_role
  username   = each.value.snowflake_username
  password   = each.value.snowflake_password
}

# Marketing Team Connections
resource "dbtcloud_snowflake_connection" "marketing_environments" {
  for_each = var.environments
  
  project_id = dbtcloud_project.marketing.id
  name       = "marketing-${each.key}-connection"
  type       = "snowflake"
  
  account    = each.value.snowflake_account
  database   = each.value.marketing_database
  warehouse  = each.value.snowflake_warehouse
  role       = each.value.marketing_role
  username   = each.value.snowflake_username
  password   = each.value.snowflake_password
}

# Finance Team Connections
resource "dbtcloud_snowflake_connection" "finance_environments" {
  for_each = var.environments
  
  project_id = dbtcloud_project.finance.id
  name       = "finance-${each.key}-connection"
  type       = "snowflake"
  
  account    = each.value.snowflake_account
  database   = each.value.finance_database
  warehouse  = each.value.snowflake_warehouse
  role       = each.value.finance_role
  username   = each.value.snowflake_username
  password   = each.value.snowflake_password
}

# Platform Team Connections
resource "dbtcloud_snowflake_connection" "platform_environments" {
  for_each = var.environments
  
  project_id = dbtcloud_project.platform.id
  name       = "platform-${each.key}-connection"
  type       = "snowflake"
  
  account    = each.value.snowflake_account
  database   = each.value.platform_database
  warehouse  = each.value.snowflake_warehouse
  role       = each.value.platform_role
  username   = each.value.snowflake_username
  password   = each.value.snowflake_password
}

# ===============================================
# ENVIRONMENTS - Per Project
# ===============================================

# Analytics Team Environments
resource "dbtcloud_environment" "analytics_environments" {
  for_each = var.environments
  
  project_id          = dbtcloud_project.analytics.id
  name               = "analytics-${each.value.name}"
  dbt_version        = each.value.dbt_version
  type               = each.value.type
  use_custom_branch  = each.value.use_custom_branch
  custom_branch      = each.value.custom_branch
  connection_id      = dbtcloud_snowflake_connection.analytics_environments[each.key].connection_id
  deployment_type    = each.value.deployment_type
}

# Marketing Team Environments
resource "dbtcloud_environment" "marketing_environments" {
  for_each = var.environments
  
  project_id          = dbtcloud_project.marketing.id
  name               = "marketing-${each.value.name}"
  dbt_version        = each.value.dbt_version
  type               = each.value.type
  use_custom_branch  = each.value.use_custom_branch
  custom_branch      = each.value.custom_branch
  connection_id      = dbtcloud_snowflake_connection.marketing_environments[each.key].connection_id
  deployment_type    = each.value.deployment_type
}

# Finance Team Environments
resource "dbtcloud_environment" "finance_environments" {
  for_each = var.environments
  
  project_id          = dbtcloud_project.finance.id
  name               = "finance-${each.value.name}"
  dbt_version        = each.value.dbt_version
  type               = each.value.type
  use_custom_branch  = each.value.use_custom_branch
  custom_branch      = each.value.custom_branch
  connection_id      = dbtcloud_snowflake_connection.finance_environments[each.key].connection_id
  deployment_type    = each.value.deployment_type
}

# Platform Team Environments
resource "dbtcloud_environment" "platform_environments" {
  for_each = var.environments
  
  project_id          = dbtcloud_project.platform.id
  name               = "platform-${each.value.name}"
  dbt_version        = each.value.dbt_version
  type               = each.value.type
  use_custom_branch  = each.value.use_custom_branch
  custom_branch      = each.value.custom_branch
  connection_id      = dbtcloud_snowflake_connection.platform_environments[each.key].connection_id
  deployment_type    = each.value.deployment_type
}

# ===============================================
# SHARED ENVIRONMENTS (for branch deployments)
# ===============================================

# Shared terraform-dev environment for ALL teams' branch deployments
resource "dbtcloud_environment" "shared_terraform_dev" {
  project_id          = dbtcloud_project.platform.id  # Owned by platform team
  name               = "terraform-dev-shared"
  dbt_version        = var.environments.dev.dbt_version
  type               = "development"
  use_custom_branch  = true
  custom_branch      = ""  # Allows any branch
  connection_id      = dbtcloud_snowflake_connection.platform_environments["dev"].connection_id
  deployment_type    = "development"
}

# ===============================================
# USER MANAGEMENT
# ===============================================

# Analytics Team Users
resource "dbtcloud_user" "analytics_users" {
  for_each = var.analytics_users
  
  email      = each.value.email
  first_name = each.value.first_name
  last_name  = each.value.last_name
  is_active  = each.value.is_active
}

# Marketing Team Users
resource "dbtcloud_user" "marketing_users" {
  for_each = var.marketing_users
  
  email      = each.value.email
  first_name = each.value.first_name
  last_name  = each.value.last_name
  is_active  = each.value.is_active
}

# Finance Team Users
resource "dbtcloud_user" "finance_users" {
  for_each = var.finance_users
  
  email      = each.value.email
  first_name = each.value.first_name
  last_name  = each.value.last_name
  is_active  = each.value.is_active
}

# Platform Team Users
resource "dbtcloud_user" "platform_users" {
  for_each = var.platform_users
  
  email      = each.value.email
  first_name = each.value.first_name
  last_name  = each.value.last_name
  is_active  = each.value.is_active
}

# ===============================================
# GROUPS AND PERMISSIONS
# ===============================================

# Analytics Team Group
resource "dbtcloud_group" "analytics_team" {
  name                    = "Analytics Team"
  assign_by_default      = false
  sso_mapping_groups     = ["analytics-team"]
  
  # Group permissions
  group_permissions = [
    {
      permission_set = "developer"
      project_id     = dbtcloud_project.analytics.id
    }
  ]
}

# Marketing Team Group
resource "dbtcloud_group" "marketing_team" {
  name                    = "Marketing Team"
  assign_by_default      = false
  sso_mapping_groups     = ["marketing-team"]
  
  # Group permissions
  group_permissions = [
    {
      permission_set = "developer"
      project_id     = dbtcloud_project.marketing.id
    }
  ]
}

# Finance Team Group
resource "dbtcloud_group" "finance_team" {
  name                    = "Finance Team"
  assign_by_default      = false
  sso_mapping_groups     = ["finance-team"]
  
  # Group permissions
  group_permissions = [
    {
      permission_set = "developer"
      project_id     = dbtcloud_project.finance.id
    }
  ]
}

# Platform/Admin Team Group
resource "dbtcloud_group" "platform_team" {
  name                    = "Platform Team"
  assign_by_default      = false
  sso_mapping_groups     = ["platform-team", "data-platform"]
  
  # Platform team has admin access to all projects
  group_permissions = [
    {
      permission_set = "admin"
      project_id     = dbtcloud_project.analytics.id
    },
    {
      permission_set = "admin"
      project_id     = dbtcloud_project.marketing.id
    },
    {
      permission_set = "admin"
      project_id     = dbtcloud_project.finance.id
    },
    {
      permission_set = "admin"
      project_id     = dbtcloud_project.platform.id
    }
  ]
}

# Data Analysts Group (read-only access across projects)
resource "dbtcloud_group" "data_analysts" {
  name                    = "Data Analysts"
  assign_by_default      = false
  sso_mapping_groups     = ["data-analysts"]
  
  # Read-only access to analytics and marketing projects
  group_permissions = [
    {
      permission_set = "analyst"
      project_id     = dbtcloud_project.analytics.id
    },
    {
      permission_set = "analyst"
      project_id     = dbtcloud_project.marketing.id
    }
  ]
}

# ===============================================
# USER GROUP MEMBERSHIPS
# ===============================================

# Analytics Team Memberships
resource "dbtcloud_user_groups" "analytics_memberships" {
  for_each = var.analytics_users
  
  user_id = dbtcloud_user.analytics_users[each.key].id
  group_ids = [
    dbtcloud_group.analytics_team.id
  ]
}

# Marketing Team Memberships
resource "dbtcloud_user_groups" "marketing_memberships" {
  for_each = var.marketing_users
  
  user_id = dbtcloud_user.marketing_users[each.key].id
  group_ids = [
    dbtcloud_group.marketing_team.id
  ]
}

# Finance Team Memberships
resource "dbtcloud_user_groups" "finance_memberships" {
  for_each = var.finance_users
  
  user_id = dbtcloud_user.finance_users[each.key].id
  group_ids = [
    dbtcloud_group.finance_team.id
  ]
}

# Platform Team Memberships
resource "dbtcloud_user_groups" "platform_memberships" {
  for_each = var.platform_users
  
  user_id = dbtcloud_user.platform_users[each.key].id
  group_ids = [
    dbtcloud_group.platform_team.id
  ]
}