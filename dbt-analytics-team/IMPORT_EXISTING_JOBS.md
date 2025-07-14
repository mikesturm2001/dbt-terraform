# Importing Existing dbt Cloud Jobs to Terraform

This guide covers importing your existing dbt Cloud jobs into Terraform management for team-specific job repositories. This is a **one-time process** you'll complete when adopting the hybrid API/Terraform approach for job management.

## 🎯 Overview

**What we're importing:**
- ✅ Production dbt Cloud Jobs (managed via Terraform)
- ✅ Job configurations (steps, schedules, settings)
- ✅ Job metadata (descriptions, tags, etc.)

**What we're NOT importing:**
- ❌ Development/branch jobs (handled via API going forward)
- ❌ Job run history (this stays in dbt Cloud)
- ❌ Temporary or test jobs (can be recreated)

**Important**: After import, you'll use the **hybrid approach**:
- **Production jobs**: Managed via Terraform (what we're importing)
- **Branch jobs**: Managed via API (using the job manager script)

## 📋 Prerequisites

### 1. Complete Infrastructure Import First

You must have completed the infrastructure import from `dbt-cloud-admin` first:
- ✅ Projects imported and managed via Terraform
- ✅ Environments imported and managed via Terraform  
- ✅ Connections imported and managed via Terraform

### 2. Install Required Tools

```bash
# Navigate to the centralized terraform-import directory
cd ../terraform-import

# Install Python dependencies
pip install -r requirements.txt

# Or if you prefer using a virtual environment
python -m venv import_env
source import_env/bin/activate  # On Windows: import_env\Scripts\activate
pip install -r requirements.txt
```

### 3. Set Environment Variables

```bash
# From your platform team's infrastructure outputs
export DBTCLOUD_ACCOUNT_ID="12345"
export DBTCLOUD_TOKEN="your_api_token_here"
export DBTCLOUD_HOST_URL="https://cloud.getdbt.com"

# Team-specific information (update for each team)
export PROJECT_ID="101"        # Analytics project ID
export TEAM_NAME="analytics-team"
export PROD_ENVIRONMENT_ID="301"    # Analytics production environment
export STAGING_ENVIRONMENT_ID="202" # Analytics staging environment
```

## 🔍 Phase 1: Discovery - What Jobs Do You Have?

### Step 1: Discover Existing Jobs

Create a Python discovery script for your team's jobs:

```python
#!/usr/bin/env python3
# discover_team_jobs.py

import os
import json
import requests
from pathlib import Path

def main():
    # Get environment variables
    account_id = os.getenv('DBTCLOUD_ACCOUNT_ID')
    token = os.getenv('DBTCLOUD_TOKEN')
    host_url = os.getenv('DBTCLOUD_HOST_URL', 'https://cloud.getdbt.com')
    project_id = os.getenv('PROJECT_ID')
    team_name = os.getenv('TEAM_NAME', 'analytics-team')
    prod_env_id = os.getenv('PROD_ENVIRONMENT_ID')
    staging_env_id = os.getenv('STAGING_ENVIRONMENT_ID')
    
    if not all([account_id, token, project_id]):
        print("❌ Error: DBTCLOUD_ACCOUNT_ID, DBTCLOUD_TOKEN, and PROJECT_ID must be set")
        return 1
    
    print(f"🔍 Discovering jobs for {team_name}...")
    print(f"Project ID: {project_id}")
    print("")
    
    base_url = f"{host_url}/api/v2/accounts/{account_id}"
    headers = {"Authorization": f"Token {token}"}
    
    # Create output directory
    output_dir = Path("job_discovery")
    output_dir.mkdir(exist_ok=True)
    
    print(f"📋 Getting all jobs for project {project_id}...")
    try:
        response = requests.get(f"{base_url}/jobs/?project_id={project_id}", headers=headers)
        response.raise_for_status()
        all_jobs = response.json()
        
        # Save all jobs
        with open(output_dir / "all_jobs.json", 'w') as f:
            json.dump(all_jobs, f, indent=2)
        
        print(f"Found {len(all_jobs.get('data', []))} total jobs")
        
        # Filter production jobs
        print("🏭 Filtering production jobs...")
        production_jobs = {
            "data": [
                job for job in all_jobs.get('data', [])
                if (
                    (prod_env_id and str(job.get('environment_id')) == prod_env_id) or
                    (staging_env_id and str(job.get('environment_id')) == staging_env_id) or
                    any(keyword in job.get('name', '').lower() for keyword in ['prod', 'production', 'staging'])
                )
            ]
        }
        
        with open(output_dir / "production_jobs.json", 'w') as f:
            json.dump(production_jobs, f, indent=2)
        
        print(f"Found {len(production_jobs['data'])} production jobs")
        
        # Filter development/branch jobs
        print("🌿 Filtering development/branch jobs...")
        development_jobs = {
            "data": [
                job for job in all_jobs.get('data', [])
                if (
                    f"{team_name}-" in job.get('name', '') or
                    any(keyword in job.get('name', '').lower() for keyword in ['dev', 'branch', 'feature'])
                ) and job not in production_jobs['data']
            ]
        }
        
        with open(output_dir / "development_jobs.json", 'w') as f:
            json.dump(development_jobs, f, indent=2)
        
        print(f"Found {len(development_jobs['data'])} development/branch jobs")
        
        print("")
        print("📊 Job Summary:")
        print("Production Jobs (will import to Terraform):")
        for job in production_jobs['data']:
            print(f"  - {job['name']} (ID: {job['id']}) - Env: {job.get('environment_id')}")
        
        print("")
        print("Development Jobs (will manage via API, not imported):")
        for job in development_jobs['data']:
            print(f"  - {job['name']} (ID: {job['id']}) - Env: {job.get('environment_id')}")
        
        print("")
        print("✅ Discovery complete! Review job_discovery/ folder.")
        
    except requests.exceptions.RequestException as e:
        print(f"❌ Error fetching jobs: {e}")
        return 1
    
    return 0

if __name__ == "__main__":
    exit(main())
```

Run the discovery:
```bash
python discover_team_jobs.py
```

### Step 2: Analyze Job Configurations

```python
#!/usr/bin/env python3
# analyze_job_configs.py

import json
from pathlib import Path

def main():
    discovery_dir = Path("job_discovery")
    
    if not discovery_dir.exists():
        print("❌ Error: Run discover_team_jobs.py first")
        return 1
    
    try:
        with open(discovery_dir / "production_jobs.json", 'r') as f:
            production_jobs = json.load(f)
        
        print("🔧 Production Job Details:")
        for job in production_jobs.get('data', []):
            steps = ", ".join(job.get('execute_steps', []))
            schedule = "Yes" if job.get('triggers', {}).get('schedule') else "No"
            description = job.get('description') or "None"
            
            print(f"""
Job: {job['name']}
  ID: {job['id']}
  Environment: {job.get('environment_id')}
  Steps: {steps}
  Schedule: {schedule}
  Description: {description}
  ---""")
    
    except FileNotFoundError:
        print("❌ Error: production_jobs.json not found")
        return 1
    
    return 0

if __name__ == "__main__":
    exit(main())
```

Run the analysis:
```bash
python analyze_job_configs.py
```

## 🔄 Phase 2: Convert Jobs to Terraform Format

### Step 1: Generate tfvars Format

Create a Python script to convert your existing jobs to `.tfvars` format:

```python
#!/usr/bin/env python3
# convert_jobs_to_tfvars.py

import json
import os
from pathlib import Path
from datetime import datetime

def main():
    discovery_dir = Path("job_discovery")
    team_name = os.getenv('TEAM_NAME', 'analytics-team')
    
    if not discovery_dir.exists():
        print("❌ Error: Run discover_team_jobs.py first")
        return 1
    
    print("🔄 Converting production jobs to tfvars format...")
    
    try:
        with open(discovery_dir / "production_jobs.json", 'r') as f:
            production_jobs = json.load(f)
        
        # Start building tfvars content
        tfvars_content = [
            "# Converted from existing dbt Cloud jobs",
            f"# Generated on: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}",
            "",
            "jobs = ["
        ]
        
        for job in production_jobs.get('data', []):
            # Clean job name (remove team prefix if present)
            job_name = job['name']
            if job_name.startswith(f"{team_name}-"):
                job_name = job_name[len(team_name)+1:]
            
            description = job.get('description') or "Imported from existing dbt Cloud job"
            execute_steps = job.get('execute_steps', [])
            steps_str = ", ".join([f'"{step}"' for step in execute_steps])
            
            # Determine schedule
            has_schedule = bool(job.get('triggers', {}).get('schedule'))
            schedule_type = "every_day" if has_schedule else "manual"
            
            # Get schedule hours (default to empty if manual)
            schedule_hours = "[]"
            if has_schedule and job.get('schedule', {}).get('hours'):
                hours = job['schedule']['hours']
                schedule_hours = str(hours) if isinstance(hours, list) else f"[{hours}]"
            
            threads = job.get('settings', {}).get('threads', 4)
            generate_docs = job.get('settings', {}).get('generate_docs', True)
            
            tfvars_content.extend([
                "  {",
                f'    name          = "{job_name}"',
                f'    description   = "{description}"',
                f"    execute_steps = [{steps_str}]",
                f'    schedule_type = "{schedule_type}"',
                f"    schedule_hours = {schedule_hours}",
                f'    job_type      = "daily"',
                f"    threads       = {threads}",
                f"    generate_docs = {str(generate_docs).lower()}",
                "  },"
            ])
        
        tfvars_content.append("]")
        
        # Write to file
        with open("converted_jobs.tfvars", 'w') as f:
            f.write('\n'.join(tfvars_content))
        
        print("✅ Conversion complete! Check converted_jobs.tfvars")
        print("")
        print("📝 Next steps:")
        print("1. Review converted_jobs.tfvars")
        print("2. Update your env_file/prod_env.tfvars with these jobs")
        print("3. Test the configuration with --dry-run")
        
    except FileNotFoundError:
        print("❌ Error: production_jobs.json not found")
        return 1
    except Exception as e:
        print(f"❌ Error during conversion: {e}")
        return 1
    
    return 0

if __name__ == "__main__":
    exit(main())
```

Run the conversion:
```bash
python convert_jobs_to_tfvars.py
```

### Step 2: Review and Clean Up Converted Jobs

```bash
# Review the converted jobs
cat converted_jobs.tfvars

# You may need to manually clean up:
# - Job naming (remove team prefixes)
# - Schedule configurations
# - Missing descriptions
# - Job categorization
```

### Step 3: Update Your Environment Files

Update your team's tfvars files with the converted jobs:

```bash
# Backup existing configurations
cp env_file/prod_env.tfvars env_file/prod_env.tfvars.backup

# Replace the jobs section in prod_env.tfvars
# with the content from converted_jobs.tfvars
```

## 🎯 Phase 3: Terraform Import Process

### Step 1: Set Up Terraform for Job Import

Ensure your Terraform is configured for the dbt-jobs module:

```bash
# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Test with dry run (don't actually create anything)
terraform plan -var-file=env_file/prod_env.tfvars
```

### Step 2: Generate Import Commands

Create a Python script to generate import commands for existing jobs:

```python
#!/usr/bin/env python3
# generate_job_import_commands.py

import json
import os
import re
from pathlib import Path

def clean_terraform_name(name, team_name):
    """Clean job name for Terraform resource naming"""
    # Remove team prefix if present
    if name.startswith(f"{team_name}-"):
        name = name[len(team_name)+1:]
    
    # Replace spaces and hyphens with underscores, convert to lowercase
    cleaned = re.sub(r'[-\s]+', '_', name.lower())
    # Remove non-alphanumeric characters except underscores
    cleaned = re.sub(r'[^a-z0-9_]', '', cleaned)
    return cleaned

def main():
    discovery_dir = Path("job_discovery")
    team_name = os.getenv('TEAM_NAME', 'analytics-team')
    
    if not discovery_dir.exists():
        print("❌ Error: Run discover_team_jobs.py first")
        return 1
    
    print("🔧 Generating Terraform import commands for production jobs...")
    
    try:
        with open(discovery_dir / "production_jobs.json", 'r') as f:
            production_jobs = json.load(f)
        
        import_commands = []
        
        for job in production_jobs.get('data', []):
            job_id = job['id']
            job_name = job['name']
            
            # Clean up job name for Terraform resource name
            terraform_name = clean_terraform_name(job_name, team_name)
            
            import_command = f"terraform import module.team_jobs.dbtcloud_job.{terraform_name} {job_id}"
            import_commands.append(import_command)
        
        # Save commands to file
        with open("job_import_commands.txt", 'w') as f:
            f.write('\n'.join(import_commands))
        
        print("✅ Import commands generated in job_import_commands.txt")
        print("")
        print(f"Generated {len(import_commands)} import commands:")
        for cmd in import_commands:
            print(cmd)
    
    except FileNotFoundError:
        print("❌ Error: production_jobs.json not found")
        return 1
    except Exception as e:
        print(f"❌ Error generating import commands: {e}")
        return 1
    
    return 0

if __name__ == "__main__":
    exit(main())
```

Run the script:
```bash
python generate_job_import_commands.py
```

### Step 3: Execute Job Imports

**Important**: This will import your existing jobs into Terraform management.

```python
#!/usr/bin/env python3
# execute_job_imports.py

import subprocess
import sys
from pathlib import Path

def safe_import(import_command):
    """Safely execute a terraform import command"""
    print(f"Executing: {import_command}")
    try:
        result = subprocess.run(
            import_command.split(),
            capture_output=True,
            text=True,
            check=False
        )
        if result.returncode == 0:
            print("  ✅ Import successful")
        else:
            print("  ⚠️  Import failed or resource already imported")
            if result.stderr:
                print(f"     Error: {result.stderr.strip()}")
    except Exception as e:
        print(f"  ❌ Error executing import: {e}")
    print("")

def main():
    if not Path("job_import_commands.txt").exists():
        print("❌ Error: Run generate_job_import_commands.py first")
        return 1
    
    print("🚀 Starting job import process...")
    print("⚠️  This will import your existing production jobs into Terraform management.")
    print("")
    
    # Read import commands
    with open("job_import_commands.txt", 'r') as f:
        import_commands = [line.strip() for line in f if line.strip()]
    
    print(f"Found {len(import_commands)} jobs to import")
    
    # Confirm with user
    confirm = input("Are you sure you want to proceed? (yes/no): ")
    if confirm.lower() != "yes":
        print("❌ Import cancelled.")
        return 0
    
    # Execute each import command
    print("\n📥 Executing import commands...")
    for import_cmd in import_commands:
        safe_import(import_cmd)
    
    print("✅ Import process complete!")
    print("")
    print("🔍 Verifying imports...")
    
    # Run terraform plan to verify
    try:
        result = subprocess.run(
            ["terraform", "plan", "-var-file=env_file/prod_env.tfvars"],
            check=False
        )
    except Exception as e:
        print(f"❌ Error running terraform plan: {e}")
    
    print("")
    print("📋 Next steps:")
    print("1. Review the terraform plan output above")
    print("2. If plan shows unexpected changes, update your tfvars to match existing jobs")
    print("3. Run 'terraform plan' again until it shows 'No changes'")
    print("4. Your jobs are now managed by Terraform!")
    
    return 0

if __name__ == "__main__":
    exit(main())
```

Run the import:
```bash
python execute_job_imports.py
```

## 🧪 Phase 4: Testing and Validation

### Step 1: Validate Terraform State

```bash
# Check what jobs are in Terraform state
terraform state list | grep dbtcloud_job

# Verify plan shows no changes (or only expected changes)
terraform plan -var-file=env_file/prod_env.tfvars

# If plan shows differences, check job details
terraform show module.team_jobs.dbtcloud_job.specific_job_name
```

### Step 2: Test with Staging Environment

```bash
# Test with staging environment first
terraform plan -var-file=env_file/test_env.tfvars

# Apply to staging to verify everything works
terraform apply -var-file=env_file/test_env.tfvars
```

### Step 3: Validate API Job Management Still Works

```bash
# Test the API job manager still works for development
python scripts/dbt_job_manager.py deploy --config env_file/dev_env.tfvars --dry-run

# Test cleanup functionality
python scripts/dbt_job_manager.py cleanup --older-than 30 --dry-run
```

## 🔄 Phase 5: Handle Development Jobs

### Step 1: Clean Up Development Jobs (Optional)

If you have many old development/branch jobs, clean them up:

```python
#!/usr/bin/env python3
# cleanup_old_jobs.py

import json
from pathlib import Path
from datetime import datetime, timedelta

def main():
    discovery_dir = Path("job_discovery")
    
    if not discovery_dir.exists():
        print("❌ Error: Run discover_team_jobs.py first")
        return 1
    
    try:
        with open(discovery_dir / "development_jobs.json", 'r') as f:
            development_jobs = json.load(f)
        
        # Calculate cutoff date (7 days ago)
        cutoff_date = datetime.now() - timedelta(days=7)
        
        print("🧹 Analyzing development jobs for cleanup...")
        old_jobs = []
        
        for job in development_jobs.get('data', []):
            created_at_str = job.get('created_at')
            if created_at_str:
                try:
                    created_at = datetime.fromisoformat(created_at_str.replace('Z', '+00:00'))
                    if created_at < cutoff_date:
                        old_jobs.append(job)
                        print(f"OLD: {job['name']} (ID: {job['id']}) - Created: {created_at_str}")
                except ValueError:
                    print(f"⚠️  Could not parse date for job: {job['name']}")
        
        print(f"\nFound {len(old_jobs)} old development jobs (>7 days)")
        
        if old_jobs:
            print("\n💡 To clean up these jobs, run:")
            print("python scripts/dbt_job_manager.py cleanup --older-than 7")
        else:
            print("\n✅ No old development jobs found!")
    
    except FileNotFoundError:
        print("❌ Error: development_jobs.json not found")
        return 1
    
    return 0

if __name__ == "__main__":
    exit(main())
```

Run the cleanup analysis:
```bash
python cleanup_old_jobs.py

# Use the job manager to clean up old development jobs
python scripts/dbt_job_manager.py cleanup --older-than 7
```

### Step 2: Transition to API-Based Development

From now on, all development jobs will be managed via the API:

```bash
# Create a new development job via API
python scripts/dbt_job_manager.py deploy --config env_file/dev_env.tfvars

# Verify it was created with proper naming
python scripts/dbt_job_manager.py list --details
```

## 🚨 Troubleshooting Common Issues

### Issue: Import fails with "resource not found"
```bash
# Verify job still exists in dbt Cloud
curl -H "Authorization: Token $DBTCLOUD_TOKEN" \
  "$DBTCLOUD_HOST_URL/api/v2/accounts/$DBTCLOUD_ACCOUNT_ID/jobs/$JOB_ID"

# Check if job was moved to different project
curl -H "Authorization: Token $DBTCLOUD_TOKEN" \
  "$DBTCLOUD_HOST_URL/api/v2/accounts/$DBTCLOUD_ACCOUNT_ID/jobs/" | \
  jq ".data[] | select(.id == $JOB_ID)"
```

### Issue: Terraform plan shows unexpected changes
```bash
# Get current job configuration from dbt Cloud
curl -H "Authorization: Token $DBTCLOUD_TOKEN" \
  "$DBTCLOUD_HOST_URL/api/v2/accounts/$DBTCLOUD_ACCOUNT_ID/jobs/$JOB_ID" | jq .

# Compare with Terraform configuration
terraform show module.team_jobs.dbtcloud_job.job_name

# Update your tfvars to match the existing configuration exactly
```

### Issue: Job naming conflicts
```bash
# Check for duplicate job names
cat job_discovery/production_jobs.json | jq -r '.data[].name' | sort | uniq -d

# Update job names in tfvars to ensure uniqueness
```

### Issue: Schedule import issues
```bash
# Schedules are complex - check the current schedule
curl -H "Authorization: Token $DBTCLOUD_TOKEN" \
  "$DBTCLOUD_HOST_URL/api/v2/accounts/$DBTCLOUD_ACCOUNT_ID/jobs/$JOB_ID" | \
  jq '.data.schedule'

# Update your tfvars schedule configuration to match
```

## 📊 Phase 6: Verification and Documentation

### Step 1: Create Import Summary

```python
#!/usr/bin/env python3
# create_import_summary.py

import subprocess
import json
import os
from pathlib import Path
from datetime import datetime

def main():
    team_name = os.getenv('TEAM_NAME', 'analytics-team')
    project_id = os.getenv('PROJECT_ID', 'unknown')
    
    print("📊 Import Summary Report")
    print("=" * 23)
    print("")
    
    print(f"Team: {team_name}")
    print(f"Project ID: {project_id}")
    print(f"Import Date: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("")
    
    # Get imported jobs from Terraform state
    print("📋 Imported Jobs (now managed by Terraform):")
    try:
        result = subprocess.run(
            ["terraform", "state", "list"],
            capture_output=True,
            text=True,
            check=True
        )
        
        terraform_jobs = [line for line in result.stdout.split('\n') if 'dbtcloud_job' in line]
        
        for resource in terraform_jobs:
            if resource.strip():
                # Get job name from terraform show
                try:
                    show_result = subprocess.run(
                        ["terraform", "show", resource.strip()],
                        capture_output=True,
                        text=True,
                        check=False
                    )
                    
                    # Extract job name from output
                    for line in show_result.stdout.split('\n'):
                        if 'name' in line and '=' in line:
                            job_name = line.split('=')[1].strip().strip('"')
                            print(f"  ✅ {job_name}")
                            break
                    else:
                        print(f"  ✅ {resource.strip()}")
                except:
                    print(f"  ✅ {resource.strip()}")
        
        if not terraform_jobs:
            print("  (No jobs found in Terraform state)")
    
    except subprocess.CalledProcessError:
        print("  ❌ Error reading Terraform state")
    
    # Get development jobs
    print("")
    print("🌿 Development Jobs (managed by API):")
    try:
        discovery_dir = Path("job_discovery")
        if (discovery_dir / "development_jobs.json").exists():
            with open(discovery_dir / "development_jobs.json", 'r') as f:
                development_jobs = json.load(f)
            
            for job in development_jobs.get('data', []):
                print(f"  🔄 {job['name']}")
            
            if not development_jobs.get('data'):
                print("  (No development jobs found)")
        else:
            print("  (No development jobs file found)")
    
    except Exception as e:
        print(f"  ❌ Error reading development jobs: {e}")
    
    print("")
    print("📈 Next Steps:")
    print("  1. All production jobs are now managed by Terraform")
    print("  2. Use 'terraform apply' for production job changes")
    print("  3. Use API job manager for development/branch jobs")
    print("  4. Regular cleanup of development jobs is automated")
    
    return 0

if __name__ == "__main__":
    exit(main())
```

Run the summary:
```bash
python create_import_summary.py > IMPORT_SUMMARY.md
```

### Step 2: Update Team Documentation

Add to your team's README:

```markdown
## 🔄 Job Management Post-Import

After completing the job import process:

### Production Jobs (Terraform-managed)
- Located in: `env_file/prod_env.tfvars` and `env_file/test_env.tfvars`
- Deploy with: `terraform apply -var-file=env_file/prod_env.tfvars`
- Require: Manual approval for production changes

### Development Jobs (API-managed)  
- Deploy with: `python scripts/dbt_job_manager.py deploy --config env_file/dev_env.tfvars`
- Automatic cleanup: Jobs older than 7 days are removed
- Naming: `{team}-{branch}-{user}-{job}`

### Migration Complete ✅
- Imported X production jobs to Terraform management
- Set up API-based development job workflow
- Configured automatic cleanup for branch jobs
```

## ✅ Success Criteria

You'll know the import is successful when:

1. **All production jobs imported**: `terraform state list` shows your production jobs
2. **No unexpected changes**: `terraform plan` shows no changes (or only expected ones)
3. **API jobs work**: Development job deployment via API works correctly
4. **Cleanup works**: Old development jobs can be cleaned up via script
5. **Documentation updated**: Team knows how to use new hybrid workflow

## 🎯 Final Steps

After successful import:

1. **Train your team** on the new hybrid workflow
2. **Set up CI/CD** for production job changes via Terraform
3. **Schedule regular cleanup** of development jobs
4. **Monitor and iterate** on the job configurations

## 🔒 Important Notes

- **This is a one-time process** - don't re-import existing jobs
- **Production jobs are now immutable** except through Terraform
- **Development workflow changes** - use API for branch jobs
- **Backup your job configurations** before making changes
- **Test in staging first** before applying to production

---

**Congratulations!** Your team's dbt Cloud jobs are now properly managed with the hybrid Terraform/API approach! 🎉