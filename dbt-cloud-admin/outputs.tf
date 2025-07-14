# ===============================================
# PROJECT OUTPUTS - For teams to reference
# ===============================================

output "analytics_project" {
  description = "Analytics Team project details"
  value = {
    project_id   = dbtcloud_project.analytics.id
    project_name = dbtcloud_project.analytics.name
  }
}

output "marketing_project" {
  description = "Marketing Team project details"
  value = {
    project_id   = dbtcloud_project.marketing.id
    project_name = dbtcloud_project.marketing.name
  }
}

output "finance_project" {
  description = "Finance Team project details"
  value = {
    project_id   = dbtcloud_project.finance.id
    project_name = dbtcloud_project.finance.name
  }
}

output "platform_project" {
  description = "Platform Team project details"
  value = {
    project_id   = dbtcloud_project.platform.id
    project_name = dbtcloud_project.platform.name
  }
}

# ===============================================
# ENVIRONMENT OUTPUTS - For teams to reference
# ===============================================

output "analytics_environments" {
  description = "Analytics Team environments"
  value = {
    for env_key, env in dbtcloud_environment.analytics_environments : env_key => {
      environment_id   = env.environment_id
      name            = env.name
      type            = env.type
      dbt_version     = env.dbt_version
      connection_id   = env.connection_id
    }
  }
}

output "marketing_environments" {
  description = "Marketing Team environments"
  value = {
    for env_key, env in dbtcloud_environment.marketing_environments : env_key => {
      environment_id   = env.environment_id
      name            = env.name
      type            = env.type
      dbt_version     = env.dbt_version
      connection_id   = env.connection_id
    }
  }
}

output "finance_environments" {
  description = "Finance Team environments"
  value = {
    for env_key, env in dbtcloud_environment.finance_environments : env_key => {
      environment_id   = env.environment_id
      name            = env.name
      type            = env.type
      dbt_version     = env.dbt_version
      connection_id   = env.connection_id
    }
  }
}

output "platform_environments" {
  description = "Platform Team environments"
  value = {
    for env_key, env in dbtcloud_environment.platform_environments : env_key => {
      environment_id   = env.environment_id
      name            = env.name
      type            = env.type
      dbt_version     = env.dbt_version
      connection_id   = env.connection_id
    }
  }
}

# ===============================================
# SHARED ENVIRONMENT - For branch deployments
# ===============================================

output "shared_terraform_dev_environment" {
  description = "Shared development environment for all teams' branch deployments"
  value = {
    environment_id = dbtcloud_environment.shared_terraform_dev.environment_id
    name          = dbtcloud_environment.shared_terraform_dev.name
    project_id    = dbtcloud_environment.shared_terraform_dev.project_id
  }
}

# ===============================================
# TEAM REFERENCE GUIDE - What teams need to know
# ===============================================

output "team_reference_guide" {
  description = "Environment IDs and project IDs for each team to use in their configurations"
  value = {
    analytics_team = {
      project_id = dbtcloud_project.analytics.id
      environments = {
        for env_key, env in dbtcloud_environment.analytics_environments : 
        env_key => env.environment_id
      }
      shared_dev_environment_id = dbtcloud_environment.shared_terraform_dev.environment_id
    }
    
    marketing_team = {
      project_id = dbtcloud_project.marketing.id
      environments = {
        for env_key, env in dbtcloud_environment.marketing_environments : 
        env_key => env.environment_id
      }
      shared_dev_environment_id = dbtcloud_environment.shared_terraform_dev.environment_id
    }
    
    finance_team = {
      project_id = dbtcloud_project.finance.id
      environments = {
        for env_key, env in dbtcloud_environment.finance_environments : 
        env_key => env.environment_id
      }
      shared_dev_environment_id = dbtcloud_environment.shared_terraform_dev.environment_id
    }
    
    platform_team = {
      project_id = dbtcloud_project.platform.id
      environments = {
        for env_key, env in dbtcloud_environment.platform_environments : 
        env_key => env.environment_id
      }
      shared_dev_environment_id = dbtcloud_environment.shared_terraform_dev.environment_id
    }
  }
}

# ===============================================
# USER AND GROUP OUTPUTS
# ===============================================

output "analytics_team_group" {
  description = "Analytics team group details"
  value = {
    group_id = dbtcloud_group.analytics_team.id
    name     = dbtcloud_group.analytics_team.name
  }
}

output "marketing_team_group" {
  description = "Marketing team group details"
  value = {
    group_id = dbtcloud_group.marketing_team.id
    name     = dbtcloud_group.marketing_team.name
  }
}

output "finance_team_group" {
  description = "Finance team group details"
  value = {
    group_id = dbtcloud_group.finance_team.id
    name     = dbtcloud_group.finance_team.name
  }
}

output "platform_team_group" {
  description = "Platform team group details"
  value = {
    group_id = dbtcloud_group.platform_team.id
    name     = dbtcloud_group.platform_team.name
  }
}

# ===============================================
# REPOSITORY OUTPUTS
# ===============================================

output "analytics_repository" {
  description = "Analytics team repository details"
  value = length(dbtcloud_repository.analytics) > 0 ? {
    repository_id = dbtcloud_repository.analytics[0].repository_id
    remote_url    = dbtcloud_repository.analytics[0].remote_url
  } : null
}

output "marketing_repository" {
  description = "Marketing team repository details"
  value = length(dbtcloud_repository.marketing) > 0 ? {
    repository_id = dbtcloud_repository.marketing[0].repository_id
    remote_url    = dbtcloud_repository.marketing[0].remote_url
  } : null
}

output "finance_repository" {
  description = "Finance team repository details"
  value = length(dbtcloud_repository.finance) > 0 ? {
    repository_id = dbtcloud_repository.finance[0].repository_id
    remote_url    = dbtcloud_repository.finance[0].remote_url
  } : null
}

output "platform_repository" {
  description = "Platform team repository details"
  value = length(dbtcloud_repository.platform) > 0 ? {
    repository_id = dbtcloud_repository.platform[0].repository_id
    remote_url    = dbtcloud_repository.platform[0].remote_url
  } : null
}