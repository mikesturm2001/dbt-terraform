# Importing Existing dbt Cloud Infrastructure to Terraform

This guide walks you through importing your existing dbt Cloud accounts, projects, environments, connections, and users into Terraform management. This is a **one-time process** you'll complete when adopting Terraform for existing dbt Cloud infrastructure.

## 🎯 Overview

**What we're importing:**
- ✅ dbt Cloud Projects
- ✅ Environments (dev, staging, prod)
- ✅ Snowflake Connections
- ✅ Users and User Groups
- ✅ Repositories (if configured)

**What we're NOT importing:**
- ❌ Jobs (handled separately - see job import guide)
- ❌ API tokens (security sensitive)
- ❌ Webhooks (typically recreated)

## 📋 Prerequisites

### 1. Install Required Tools

```bash
# Install Terraform (if not already installed)
# macOS
brew install terraform

# Linux
sudo apt-get install terraform

# Windows (use Chocolatey)
choco install terraform
```

### 2. Install Python Dependencies

```bash
# Navigate to the terraform-import directory
cd ../terraform-import

# Install Python dependencies
pip install -r requirements.txt

# Or if you prefer using a virtual environment
python -m venv import_env
source import_env/bin/activate  # On Windows: import_env\Scripts\activate
pip install -r requirements.txt
```

### 3. Verify Python Installation

```bash
# Verify Python 3.7+ is installed
python --version
# or
python3 --version

# If Python is not installed:
# macOS: brew install python
# Linux: sudo apt-get install python3 python3-pip
# Windows: Download from python.org
```

### 4. Gather dbt Cloud Information

You'll need:
- **Account ID**: Found in dbt Cloud URL (`https://cloud.getdbt.com/accounts/{ACCOUNT_ID}/`)
- **API Token**: Generate in dbt Cloud → Account Settings → API Access
- **Host URL**: `https://cloud.getdbt.com` (or your custom domain)

## 🔍 Phase 1: Discovery - What Do You Have?

### Step 1: Set Environment Variables

```bash
# Set your dbt Cloud credentials
export DBTCLOUD_ACCOUNT_ID="12345"
export DBTCLOUD_TOKEN="dbt_abc123xyz789"
export DBTCLOUD_HOST_URL="https://cloud.getdbt.com"
```

### Step 2: Discover Your Current Resources

Use the centralized discovery script:

```bash
# Navigate to terraform-import directory
cd ../terraform-import

# Run the discovery script
python discover_dbt_resources.py
```

This script will:
- Discover all projects, environments, connections, users, groups, and repositories
- Save detailed JSON files in `dbt_discovery/` folder
- Provide a summary of what was found

**Script Location**: `../terraform-import/discover_dbt_resources.py`

### Step 3: Review Your Current Setup

Review the discovered resources:

```bash
# Review the JSON files created by discovery
ls -la dbt_discovery/

# Quick summary of discovered resources
echo "📊 Projects:" && jq '.data[] | "- \(.name) (ID: \(.id))"' dbt_discovery/projects.json -r
echo "🌍 Environments:" && jq '.data[] | "- \(.name) (ID: \(.id)) - Project: \(.project_id)"' dbt_discovery/environments.json -r
echo "🔗 Connections:" && jq '.data[] | "- \(.name) (ID: \(.id)) - Type: \(.type)"' dbt_discovery/connections.json -r
echo "👥 Users:" && jq '.data | length' dbt_discovery/users.json
```

**Discovery Output**: All resource details are saved in `dbt_discovery/` JSON files for your review.

## 🔧 Phase 2: Import Process

### Step 1: Create Basic Terraform Configuration

Create your initial Terraform files:

```bash
# Create main directory structure
mkdir -p terraform_import
cd terraform_import
```

**File: `versions.tf`**
```hcl
terraform {
  required_version = ">= 1.0"
  
  required_providers {
    dbtcloud = {
      source  = "dbt-labs/dbtcloud"
      version = "~> 0.3"
    }
  }
}

provider "dbtcloud" {
  account_id = var.dbtcloud_account_id
  token      = var.dbtcloud_token
  host_url   = var.dbtcloud_host_url
}
```

**File: `variables.tf`**
```hcl
variable "dbtcloud_account_id" {
  type        = string
  description = "dbt Cloud Account ID"
}

variable "dbtcloud_token" {
  type        = string
  description = "dbt Cloud API Token"
  sensitive   = true
}

variable "dbtcloud_host_url" {
  type        = string
  description = "dbt Cloud Host URL"
  default     = "https://cloud.getdbt.com"
}
```

**File: `terraform.tfvars`**
```hcl
dbtcloud_account_id = "12345"
dbtcloud_token      = "dbt_abc123xyz789"
dbtcloud_host_url   = "https://cloud.getdbt.com"
```

### Step 2: Generate Import Commands

Use the centralized script to generate all import commands:

```bash
# Generate import commands for all discovered resources
python generate_import_commands.py

# Review the generated commands
cat import_commands.txt
```

This script will:
- Read from the `dbt_discovery/` folder
- Generate properly formatted Terraform import commands
- Save commands to `import_commands.txt`
- Handle resource naming conflicts automatically

**Script Location**: `../terraform-import/generate_import_commands.py`

### Step 3: Create Terraform Resource Definitions

Now create the actual Terraform resources to match your existing infrastructure:

**File: `main.tf`** (Start with projects)
```hcl
# ===== PROJECTS =====
# Replace with your actual project names and update after import

resource "dbtcloud_project" "analytics_team" {
  name = "Analytics Team"
}

resource "dbtcloud_project" "marketing_team" {
  name = "Marketing Team"
}

# Add more projects as discovered...
```

### Step 4: Initialize Terraform

```bash
terraform init
```

### Step 5: Import Projects First

```bash
# Start with projects (replace IDs with your actual ones)
terraform import dbtcloud_project.analytics_team 101
terraform import dbtcloud_project.marketing_team 102

# Verify import worked
terraform plan
```

You should see a plan with **configuration changes only** (not resource creation/deletion).

### Step 6: Fix Configuration Mismatches

If `terraform plan` shows differences, update your Terraform config to match reality:

```bash
# If you see differences, get the exact current values
curl -s -H "Authorization: Token $DBTCLOUD_TOKEN" \
  "$DBTCLOUD_HOST_URL/api/v2/accounts/$DBTCLOUD_ACCOUNT_ID/projects/101" | jq .

# Update your main.tf to match exactly
```

### Step 7: Import Environments

Add environments to `main.tf`:
```hcl
# ===== ENVIRONMENTS =====
resource "dbtcloud_environment" "analytics_prod" {
  project_id          = dbtcloud_project.analytics_team.id
  name               = "Production"
  type               = "deployment"
  dbt_version        = "1.7.0-latest"
  # ... other attributes to match your existing setup
}
```

Import them:
```bash
terraform import dbtcloud_environment.analytics_prod 201
terraform plan  # Should show no changes
```

### Step 8: Import Connections

Add connections to `main.tf`:
```hcl
# ===== CONNECTIONS =====
resource "dbtcloud_snowflake_connection" "analytics_prod" {
  project_id = dbtcloud_project.analytics_team.id
  name       = "Analytics Production"
  type       = "snowflake"
  account    = "company.snowflakecomputing.com"
  database   = "ANALYTICS_PROD"
  warehouse  = "COMPUTE_WH"
  # ... match your existing connection settings
}
```

Import:
```bash
terraform import dbtcloud_snowflake_connection.analytics_prod 301
```

### Step 9: Import Users and Groups

This is more complex due to relationships. Add to `main.tf`:
```hcl
# ===== USERS =====
resource "dbtcloud_user" "sarah_chen" {
  email      = "sarah.chen@company.com"
  first_name = "Sarah"
  last_name  = "Chen"
  is_active  = true
}

# ===== GROUPS =====
resource "dbtcloud_group" "analytics_team" {
  name                    = "Analytics Team"
  assign_by_default      = false
  
  group_permissions = [
    {
      permission_set = "developer"
      project_id     = dbtcloud_project.analytics_team.id
    }
  ]
}
```

Import:
```bash
terraform import dbtcloud_user.sarah_chen 401
terraform import dbtcloud_group.analytics_team 501
```

## 🔧 Phase 3: Automated Complete Import

Use the automated import script for a complete infrastructure import:

```bash
# Navigate to terraform-import directory (if not already there)
cd ../terraform-import

# Run the complete automated import
python complete_import.py
```

This script will:
- Verify all prerequisites are met
- Initialize Terraform automatically
- Import all discovered resources safely
- Handle errors gracefully (skip already imported resources)
- Provide next steps guidance

**Script Location**: `../terraform-import/complete_import.py`

## 🧹 Phase 4: Cleanup and Validation

### Step 1: Validate Everything is Imported

```bash
# Check what's in your state
terraform state list

# Verify no changes needed
terraform plan

# If plan shows changes, you need to adjust your config to match reality
```

### Step 2: Create Organized File Structure

Once everything is imported, reorganize your files:

```bash
# Split into logical files
main.tf           # Projects and core resources
environments.tf   # All environments
connections.tf    # All connections  
users.tf          # User management
groups.tf         # Groups and permissions
```

### Step 3: Set Up Remote State (Recommended)

```bash
# Create backend.tf
cat > backend.tf << EOF
terraform {
  backend "s3" {
    bucket  = "your-terraform-state-bucket"
    key     = "dbt-cloud-admin/terraform.tfstate"
    region  = "us-west-2"
    encrypt = true
  }
}
EOF

# Migrate to remote state
terraform init -migrate-state
```

## 🚨 Troubleshooting Common Issues

### Issue: "Resource already exists"
```bash
# If resource is already managed elsewhere
terraform import dbtcloud_project.existing 12345
# Then remove from other state file
```

### Issue: Configuration drift after import
```bash
# Get current state of resource
terraform show dbtcloud_project.existing

# Compare with dbt Cloud API
curl -H "Authorization: Token $DBTCLOUD_TOKEN" \
  "$BASE_URL/projects/12345" | jq .

# Update Terraform config to match
```

### Issue: Import command fails
```python
# Check if resource exists in dbt Cloud using Python
import requests
response = requests.get(
    f"{base_url}/projects/12345",
    headers={"Authorization": f"Token {token}"}
)
print(response.json())

# Verify resource name in Terraform is valid
terraform validate
```

## ✅ Success Criteria

You'll know the import is successful when:

1. **`terraform state list`** shows all your existing resources
2. **`terraform plan`** shows "No changes" (or only expected changes)
3. **`terraform apply`** (if needed) completes without errors
4. Your dbt Cloud UI shows no unexpected changes

## 🎯 Next Steps

After successful import:

1. **Enhance your configuration** with the multi-team setup
2. **Add new resources** (users, environments) via Terraform
3. **Set up CI/CD** for infrastructure changes
4. **Import job configurations** (see separate job import guide)

## 🔒 Security Notes

- **Never commit sensitive tokens** to version control
- **Use environment variables** or secure secret management
- **Limit API token permissions** to minimum required
- **Enable Terraform state encryption** for remote backends

---

**This is a one-time process.** Once complete, you'll manage all future dbt Cloud infrastructure changes through Terraform! 🎉