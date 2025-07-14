# 🏗️ dbt Cloud Admin Infrastructure

This repository manages the **central dbt Cloud infrastructure** including projects, environments, and connections. This is maintained by the **Cloud Admin Team** and provides the foundation for all team job deployments.

## 🎯 Purpose

- Create and manage dbt Cloud **projects**
- Provision dbt Cloud **environments** (terraform-dev, terraform-staging, terraform-prod)
- Configure **Snowflake connections** for each environment
- Provide **environment IDs** to teams for job deployment

## 📁 Repository Structure

```
dbt-cloud-admin/
├── main.tf                    # Core infrastructure resources
├── variables.tf               # Variable definitions
├── outputs.tf                 # Environment IDs and connection details
├── versions.tf                # Provider configuration
├── .gitlab-ci.yml            # CI/CD pipeline
├── env_file/                  # Environment-specific configurations
│   ├── dev_env.tfvars        # Development account settings
│   ├── test_env.tfvars       # Test account settings
│   └── prod_env.tfvars       # Production account settings
├── backend-config/            # Terraform state configurations
│   ├── dev.hcl
│   ├── test.hcl
│   └── prod.hcl
└── README.md                 # This file
```

## 🌍 Environments Created

| Environment | Purpose | Job Types Allowed | Used By |
|------------|---------|------------------|---------|
| `terraform-dev` | Development | All (daily, hourly, on-demand) | All team branches |
| `terraform-staging` | Pre-production | daily, on-demand | Team master branches |
| `terraform-prod` | Production | daily only | Team production branches |
| `terraform-cicd` | CI/CD Testing | None (testing only) | CI/CD pipelines |

## 🚀 Deployment

### Branch Strategy
- **`branch/*`** → Deploys to dev account using `dev_env.tfvars`
- **`master`** → Deploys to shared dev account using `test_env.tfvars`  
- **`production`** → Deploys to prod account using `prod_env.tfvars`

### GitLab CI Variables
Set these in your GitLab project settings:

```bash
# Development Account
TF_VAR_dbtcloud_account_id="12345"
TF_VAR_dbtcloud_token="${DBT_DEV_TOKEN}"
TF_VAR_dbtcloud_host_url="https://dev.getdbt.com"

# Production Account  
TF_VAR_dbtcloud_account_id="67890"
TF_VAR_dbtcloud_token="${DBT_PROD_TOKEN}"
TF_VAR_dbtcloud_host_url="https://prod.getdbt.com"
```

## 📤 Outputs for Teams

After deployment, teams need these outputs for their job repositories:

```hcl
# From terraform output
environments = {
  dev = {
    environment_id = "201"
    name          = "terraform-dev"
  }
  staging = {
    environment_id = "202" 
    name          = "terraform-staging"
  }
  prod = {
    environment_id = "302"
    name          = "terraform-prod"
  }
}
```

## 🔧 Configuration

### Snowflake Connections
Each environment gets its own Snowflake connection with isolated:
- **Databases**: `DEV_DB`, `STAGING_DB`, `PROD_DB`
- **Warehouses**: `DEV_WH`, `STAGING_WH`, `PROD_WH`  
- **Roles**: `DEV_ROLE`, `STAGING_ROLE`, `PROD_ROLE`

### Multiple dbt Cloud Accounts
- **Development Account** (`dev.getdbt.com`) - For development and testing
- **Production Account** (`prod.getdbt.com`) - For production workloads

## 🧹 Cleanup Jobs

The admin team manages cleanup of orphaned branch jobs:

```sql
-- Weekly cleanup of jobs older than 7 days
DELETE FROM dbt_cloud_jobs 
WHERE job_name LIKE '%feature-%' 
AND created_date < NOW() - INTERVAL '7 days'
```

## 🛡️ Security

- **API tokens** stored in GitLab CI variables
- **Snowflake credentials** managed per environment
- **State files** stored in GitLab with locking
- **Access control** via GitLab project permissions

## 📞 Support

For infrastructure requests or issues:
- 📧 Email: cloud-admin-team@company.com
- 💬 Slack: #dbt-cloud-admin
- 🎫 Jira: Create infrastructure ticket

---

**Maintained by**: Cloud Admin Team  
**Last Updated**: 2024-12-11