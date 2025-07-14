# dbt Cloud Terraform Import Scripts

This directory contains Python scripts to help import existing dbt Cloud infrastructure and jobs into Terraform management. These scripts are shared across all team projects and eliminate the need for duplicate import code.

## 🎯 Overview

**Infrastructure Import Scripts:**
- `discover_dbt_resources.py` - Discover all dbt Cloud resources in your account
- `generate_import_commands.py` - Generate Terraform import commands for infrastructure
- `complete_import.py` - Automated complete infrastructure import

**Job Import Scripts:**
- `discover_team_jobs.py` - Discover team-specific jobs (analytics)
- `discover_marketing_jobs.py` - Discover marketing jobs with categorization
- `convert_jobs_to_tfvars.py` - Convert jobs to Terraform tfvars format
- `generate_job_import_commands.py` - Generate job import commands
- `execute_job_imports.py` - Execute job imports safely

## 📋 Prerequisites

### 1. Python Environment
```bash
# Install Python dependencies
pip install -r requirements.txt

# Or use virtual environment (recommended)
python -m venv import_env
source import_env/bin/activate  # On Windows: import_env\Scripts\activate
pip install -r requirements.txt
```

### 2. Environment Variables
Set these before running any scripts:

```bash
# Required for all scripts
export DBTCLOUD_ACCOUNT_ID="12345"
export DBTCLOUD_TOKEN="your_api_token_here"
export DBTCLOUD_HOST_URL="https://cloud.getdbt.com"  # Optional, defaults to this

# Required for job import scripts
export PROJECT_ID="101"                    # Your team's project ID
export TEAM_NAME="analytics-team"          # Your team name
export PROD_ENVIRONMENT_ID="301"           # Production environment ID
export STAGING_ENVIRONMENT_ID="202"        # Staging environment ID
```

## 🏗️ Infrastructure Import Workflow

### Step 1: Discover Resources
```bash
python discover_dbt_resources.py
```
Creates `dbt_discovery/` folder with JSON files for all resources.

### Step 2: Generate Import Commands
```bash
python generate_import_commands.py
```
Creates `import_commands.txt` with Terraform import commands.

### Step 3: Execute Complete Import (Automated)
```bash
python complete_import.py
```
Automatically imports all discovered resources into Terraform.

## 🔧 Job Import Workflow

### For Analytics Teams
```bash
# 1. Discover team jobs
python discover_team_jobs.py

# 2. Convert to tfvars format
python convert_jobs_to_tfvars.py

# 3. Generate import commands
python generate_job_import_commands.py

# 4. Execute imports
python execute_job_imports.py
```

### For Marketing Teams
```bash
# 1. Discover marketing jobs (with categorization)
python discover_marketing_jobs.py

# 2. Convert to tfvars format (marketing-specific)
python convert_jobs_to_tfvars.py

# 3. Generate import commands (with category prefixes)
python generate_job_import_commands.py

# 4. Execute imports
python execute_job_imports.py
```

## 📁 Output Files

### Infrastructure Discovery
- `dbt_discovery/projects.json` - All projects
- `dbt_discovery/environments.json` - All environments
- `dbt_discovery/connections.json` - All connections
- `dbt_discovery/users.json` - All users
- `dbt_discovery/groups.json` - All groups
- `dbt_discovery/repositories.json` - All repositories

### Job Discovery
- `job_discovery/all_jobs.json` - All jobs for the project
- `job_discovery/production_jobs.json` - Production jobs (for Terraform)
- `job_discovery/development_jobs.json` - Development jobs (for API)

### Marketing Job Discovery
- `marketing_job_discovery/all_marketing_jobs.json` - All marketing jobs
- `marketing_job_discovery/attribution_jobs.json` - Attribution jobs
- `marketing_job_discovery/campaign_jobs.json` - Campaign jobs
- `marketing_job_discovery/customer_ltv_jobs.json` - Customer LTV jobs
- `marketing_job_discovery/executive_jobs.json` - Executive jobs
- `marketing_job_discovery/platform_integration_jobs.json` - Platform jobs
- `marketing_job_discovery/production_marketing_jobs.json` - Production jobs

### Generated Files
- `import_commands.txt` - Infrastructure import commands
- `job_import_commands.txt` - Analytics job import commands
- `marketing_import_commands.txt` - Marketing job import commands
- `converted_analytics_jobs.tfvars` - Analytics jobs in tfvars format
- `converted_marketing_jobs.tfvars` - Marketing jobs in tfvars format

## 🚀 Usage Examples

### Complete Infrastructure Import
```bash
# Set environment variables
export DBTCLOUD_ACCOUNT_ID="12345"
export DBTCLOUD_TOKEN="dbt_abc123xyz789"

# Run complete automated import
python complete_import.py
```

### Analytics Team Job Import
```bash
# Set team-specific variables
export PROJECT_ID="101"
export TEAM_NAME="analytics-team"
export PROD_ENVIRONMENT_ID="301"
export STAGING_ENVIRONMENT_ID="202"

# Discover and import jobs
python discover_team_jobs.py
python convert_jobs_to_tfvars.py
python generate_job_import_commands.py
python execute_job_imports.py
```

### Marketing Team Job Import
```bash
# Set marketing team variables
export PROJECT_ID="102"
export TEAM_NAME="marketing-team"
export PROD_ENVIRONMENT_ID="311"
export STAGING_ENVIRONMENT_ID="212"

# Discover and import marketing jobs
python discover_marketing_jobs.py
python convert_jobs_to_tfvars.py
python generate_job_import_commands.py
python execute_job_imports.py
```

## 🔍 Troubleshooting

### Common Issues

#### "No module named 'requests'"
```bash
pip install requests python-dateutil
```

#### "Error: Run discover_* first"
Make sure to run discovery scripts before conversion/import scripts.

#### "Error: DBTCLOUD_ACCOUNT_ID must be set"
Set all required environment variables before running scripts.

#### Import command fails
- Verify the resource still exists in dbt Cloud
- Check if resource was already imported
- Ensure Terraform configuration matches existing resource

### Debug Mode
Add debugging to any script:
```python
import logging
logging.basicConfig(level=logging.DEBUG)
```

## 🔐 Security Best Practices

- Never commit API tokens to version control
- Use environment variables or secure secret management
- Limit API token permissions to minimum required
- Run imports in a secure environment

## 📚 Related Documentation

- [Platform Team Infrastructure Import](../dbt-cloud-admin/IMPORT_EXISTING_INFRASTRUCTURE.md)
- [Analytics Team Job Import](../dbt-analytics-team/IMPORT_EXISTING_JOBS.md)
- [Marketing Team Job Import](../dbt-marketing-analytics-team/IMPORT_EXISTING_JOBS.md)

---

**This is a one-time process per resource.** Once imported, manage all changes through Terraform and the hybrid API/Terraform approach for jobs.