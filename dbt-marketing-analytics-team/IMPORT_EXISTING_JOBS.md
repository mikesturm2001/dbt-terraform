# Importing Existing Marketing Analytics Jobs to Terraform

This guide covers importing your existing Marketing Analytics dbt Cloud jobs into Terraform management. This is a **one-time process** you'll complete when adopting the hybrid API/Terraform approach for job management.

**This guide is specific to the Marketing Analytics Team.** For infrastructure import, see the `dbt-cloud-admin` project.

## 🎯 Marketing Analytics Focus

**What we're importing:**
- ✅ Marketing attribution jobs
- ✅ Campaign performance tracking jobs  
- ✅ Customer LTV modeling jobs
- ✅ Executive marketing dashboard jobs
- ✅ Ad platform integration jobs

**Job Categories We Expect:**
- 🎯 **Attribution Models**: Multi-touch attribution analysis
- 📊 **Campaign Performance**: Cross-platform campaign tracking
- 👥 **Customer Analytics**: LTV modeling and segmentation
- 📱 **Platform Integration**: Facebook, Google, LinkedIn ad sync
- 📈 **Executive Reporting**: C-level marketing dashboards

## 📋 Prerequisites

### 1. Infrastructure Must Be Imported First

Ensure the platform team has completed infrastructure import:
- ✅ Marketing project imported (ID: 102)
- ✅ Marketing environments imported
- ✅ Marketing connections imported
- ✅ Marketing team users and groups imported

### 2. Set Marketing-Specific Environment Variables

```bash
# Marketing Team Configuration
export DBTCLOUD_ACCOUNT_ID="12345"
export DBTCLOUD_TOKEN="your_api_token_here"
export DBTCLOUD_HOST_URL="https://cloud.getdbt.com"

# Marketing Team Specifics (from platform team outputs)
export PROJECT_ID="102"                    # Marketing project ID
export TEAM_NAME="marketing-team"
export PROD_ENVIRONMENT_ID="311"           # marketing-prod environment
export STAGING_ENVIRONMENT_ID="212"        # marketing-staging environment
export DEV_ENVIRONMENT_ID="211"            # marketing-dev environment
export SHARED_DEV_ENVIRONMENT_ID="999"     # shared terraform-dev environment
```

## 🔍 Phase 1: Discovery - Marketing Jobs Inventory

### Step 1: Discover Marketing Jobs

Create a Python marketing-specific discovery script:

```python
#!/usr/bin/env python3
# discover_marketing_jobs.py

import os
import json
import requests
import re
from pathlib import Path

def categorize_marketing_job(job_name):
    """Categorize marketing jobs by function"""
    name_lower = job_name.lower()
    
    if re.search(r'attribution|touch|channel', name_lower):
        return 'attribution'
    elif re.search(r'campaign|performance|ads?|adwords', name_lower):
        return 'campaign'
    elif re.search(r'ltv|lifetime|customer|segment', name_lower):
        return 'customer_ltv'
    elif re.search(r'executive|dashboard|kpi|c.level', name_lower):
        return 'executive'
    elif re.search(r'facebook|google|linkedin|platform|sync', name_lower):
        return 'platform_integration'
    else:
        return 'general'

def main():
    # Get environment variables
    account_id = os.getenv('DBTCLOUD_ACCOUNT_ID')
    token = os.getenv('DBTCLOUD_TOKEN')
    host_url = os.getenv('DBTCLOUD_HOST_URL', 'https://cloud.getdbt.com')
    project_id = os.getenv('PROJECT_ID')
    prod_env_id = os.getenv('PROD_ENVIRONMENT_ID')
    staging_env_id = os.getenv('STAGING_ENVIRONMENT_ID')
    
    if not all([account_id, token, project_id]):
        print("❌ Error: DBTCLOUD_ACCOUNT_ID, DBTCLOUD_TOKEN, and PROJECT_ID must be set")
        return 1
    
    print("🎯 Discovering Marketing Analytics jobs...")
    print(f"Project ID: {project_id} (Marketing Analytics)")
    print("")
    
    base_url = f"{host_url}/api/v2/accounts/{account_id}"
    headers = {"Authorization": f"Token {token}"}
    
    # Create output directory
    output_dir = Path("marketing_job_discovery")
    output_dir.mkdir(exist_ok=True)
    
    print("📋 Getting all Marketing jobs...")
    try:
        response = requests.get(f"{base_url}/jobs/?project_id={project_id}", headers=headers)
        response.raise_for_status()
        all_marketing_jobs = response.json()
        
        # Save all jobs
        with open(output_dir / "all_marketing_jobs.json", 'w') as f:
            json.dump(all_marketing_jobs, f, indent=2)
        
        print(f"Found {len(all_marketing_jobs.get('data', []))} total Marketing jobs")
        
        # Categorize jobs by function
        print("🎯 Categorizing Marketing jobs...")
        
        categories = {
            'attribution': [],
            'campaign': [],
            'customer_ltv': [],
            'executive': [],
            'platform_integration': [],
            'general': []
        }
        
        production_jobs = []
        
        for job in all_marketing_jobs.get('data', []):
            job_name = job.get('name', '')
            category = categorize_marketing_job(job_name)
            categories[category].append(job)
            
            # Check if it's a production job
            is_production = (
                (prod_env_id and str(job.get('environment_id')) == prod_env_id) or
                (staging_env_id and str(job.get('environment_id')) == staging_env_id) or
                any(keyword in job_name.lower() for keyword in ['prod', 'production', 'staging'])
            )
            
            if is_production:
                production_jobs.append(job)
        
        # Save categorized jobs
        for category, jobs in categories.items():
            filename = f"{category}_jobs.json" if category != 'customer_ltv' else "customer_ltv_jobs.json"
            with open(output_dir / filename, 'w') as f:
                json.dump({"data": jobs}, f, indent=2)
        
        # Save production jobs
        with open(output_dir / "production_marketing_jobs.json", 'w') as f:
            json.dump({"data": production_jobs}, f, indent=2)
        
        print("✅ Marketing job categorization complete!")
        print("")
        print("📊 Marketing Job Summary:")
        print(f"🎯 Attribution Jobs: {len(categories['attribution'])}")
        print(f"📊 Campaign Jobs: {len(categories['campaign'])}")
        print(f"👥 Customer LTV Jobs: {len(categories['customer_ltv'])}")
        print(f"📈 Executive Jobs: {len(categories['executive'])}")
        print(f"📱 Platform Integration: {len(categories['platform_integration'])}")
        print(f"🏭 Production Jobs (to import): {len(production_jobs)}")
        
        print("")
        print("🏭 Production Marketing Jobs (will import to Terraform):")
        for job in production_jobs:
            print(f"  - {job['name']} (ID: {job['id']}) - Env: {job.get('environment_id')}")
        
    except requests.exceptions.RequestException as e:
        print(f"❌ Error fetching marketing jobs: {e}")
        return 1
    
    return 0

if __name__ == "__main__":
    exit(main())
```

Run the marketing discovery:
```bash
python discover_marketing_jobs.py
```

### Step 2: Analyze Marketing Job Patterns

```python
#!/usr/bin/env python3
# analyze_marketing_job_patterns.py

import json
from pathlib import Path

def get_job_category_emoji(job_name):
    """Get category emoji for marketing job"""
    name_lower = job_name.lower()
    
    if 'attribution' in name_lower:
        return "🎯 Attribution"
    elif 'campaign' in name_lower:
        return "📊 Campaign"
    elif any(keyword in name_lower for keyword in ['ltv', 'customer']):
        return "👥 Customer"
    elif any(keyword in name_lower for keyword in ['executive', 'dashboard']):
        return "📈 Executive"
    elif any(keyword in name_lower for keyword in ['platform', 'ads']):
        return "📱 Platform"
    else:
        return "🔄 General"

def main():
    discovery_dir = Path("marketing_job_discovery")
    
    if not discovery_dir.exists():
        print("❌ Error: Run discover_marketing_jobs.py first")
        return 1
    
    try:
        with open(discovery_dir / "production_marketing_jobs.json", 'r') as f:
            production_jobs = json.load(f)
        
        print("🔧 Marketing Job Details Analysis:")
        
        for job in production_jobs.get('data', []):
            steps = " → ".join(job.get('execute_steps', []))
            schedule = "Scheduled" if job.get('triggers', {}).get('schedule') else "Manual"
            tags = ", ".join(job.get('tags', []))
            description = job.get('description') or "None"
            category = get_job_category_emoji(job['name'])
            
            print(f"""
Job: {job['name']}
  ID: {job['id']}
  Environment: {job.get('environment_id')}
  Steps: {steps}
  Schedule: {schedule}
  Tags: {tags}
  Description: {description}
  Likely Category: {category}
  ---""")
    
    except FileNotFoundError:
        print("❌ Error: production_marketing_jobs.json not found")
        return 1
    
    return 0

if __name__ == "__main__":
    exit(main())
```

Run the analysis:
```bash
python analyze_marketing_job_patterns.py
```

## 🔄 Phase 2: Convert Marketing Jobs to Terraform Format

### Step 1: Generate Marketing-Specific tfvars

Create a Python marketing-focused conversion script:

```python
#!/usr/bin/env python3
# convert_marketing_jobs_to_tfvars.py

import json
import os
from pathlib import Path
from datetime import datetime

def determine_marketing_schedule(job_name):
    """Determine optimal schedule for marketing job based on category"""
    name_lower = job_name.lower()
    
    if 'attribution' in name_lower:
        return "[6]"  # Early morning for attribution
    elif 'campaign' in name_lower:
        return "[9]"  # After attribution
    elif any(keyword in name_lower for keyword in ['ltv', 'customer']):
        return "[12]"  # Midday for customer analysis
    elif any(keyword in name_lower for keyword in ['executive', 'dashboard']):
        return "[8]"  # Ready for morning meetings
    elif any(keyword in name_lower for keyword in ['platform', 'ads', 'facebook', 'google']):
        return "[6, 12, 18]"  # Multiple times for platform sync
    else:
        return "[8]"  # Default to 8 AM

def clean_marketing_job_name(job_name, team_name):
    """Clean job name for tfvars (remove team prefixes)"""
    # Remove various team prefixes
    prefixes_to_remove = [f"{team_name}-", "marketing-team-", "marketing-"]
    
    clean_name = job_name
    for prefix in prefixes_to_remove:
        if clean_name.startswith(prefix):
            clean_name = clean_name[len(prefix):]
    
    return clean_name

def main():
    discovery_dir = Path("marketing_job_discovery")
    team_name = os.getenv('TEAM_NAME', 'marketing-team')
    
    if not discovery_dir.exists():
        print("❌ Error: Run discover_marketing_jobs.py first")
        return 1
    
    print("🎯 Converting Marketing production jobs to tfvars format...")
    
    try:
        with open(discovery_dir / "production_marketing_jobs.json", 'r') as f:
            production_jobs = json.load(f)
        
        # Start building tfvars content
        tfvars_content = [
            "# Marketing Analytics Team Jobs - Converted from existing dbt Cloud",
            f"# Generated on: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}",
            "# Team: Marketing Analytics",
            "# Focus: Attribution, Campaign Performance, Customer LTV, Executive Reporting",
            "",
            "jobs = ["
        ]
        
        category_counts = {}
        
        for job in production_jobs.get('data', []):
            # Clean job name
            clean_name = clean_marketing_job_name(job['name'], team_name)
            
            description = job.get('description') or "Marketing analytics job imported from dbt Cloud"
            execute_steps = job.get('execute_steps', [])
            steps_str = ", ".join([f'"{step}"' for step in execute_steps])
            
            # Determine marketing-specific schedule
            schedule_hours = determine_marketing_schedule(job['name'])
            schedule_type = "every_day"
            
            threads = job.get('settings', {}).get('threads', 4)
            generate_docs = job.get('settings', {}).get('generate_docs', True)
            
            # Track categories for summary
            if 'attribution' in job['name'].lower():
                category_counts['attribution'] = category_counts.get('attribution', 0) + 1
            elif 'campaign' in job['name'].lower():
                category_counts['campaign'] = category_counts.get('campaign', 0) + 1
            elif any(keyword in job['name'].lower() for keyword in ['ltv', 'customer']):
                category_counts['customer'] = category_counts.get('customer', 0) + 1
            elif any(keyword in job['name'].lower() for keyword in ['executive', 'dashboard']):
                category_counts['executive'] = category_counts.get('executive', 0) + 1
            elif any(keyword in job['name'].lower() for keyword in ['platform', 'ads']):
                category_counts['platform'] = category_counts.get('platform', 0) + 1
            else:
                category_counts['general'] = category_counts.get('general', 0) + 1
            
            tfvars_content.extend([
                "  {",
                f'    name          = "{clean_name}"',
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
        with open("converted_marketing_jobs.tfvars", 'w') as f:
            f.write('\n'.join(tfvars_content))
        
        print("✅ Marketing job conversion complete! Check converted_marketing_jobs.tfvars")
        print("")
        print("📊 Converted jobs by category:")
        for category, count in category_counts.items():
            print(f"  {category}: {count} jobs")
        
    except FileNotFoundError:
        print("❌ Error: production_marketing_jobs.json not found")
        return 1
    except Exception as e:
        print(f"❌ Error during conversion: {e}")
        return 1
    
    return 0

if __name__ == "__main__":
    exit(main())
```

Run the marketing conversion:
```bash
python convert_marketing_jobs_to_tfvars.py
```

### Step 2: Review Marketing Job Categories

```bash
# Review the converted marketing jobs
echo "🎯 Reviewing converted Marketing jobs:"
cat converted_marketing_jobs.tfvars

echo ""
echo "📋 Marketing job schedule analysis:"
grep -A 10 -B 2 "schedule_hours" converted_marketing_jobs.tfvars
```

### Step 3: Update Marketing Environment Files

Update your marketing team's environment files:

```bash
# Backup existing configurations
cp env_file/prod_env.tfvars env_file/prod_env.tfvars.backup.$(date +%Y%m%d)

# Create production environment with converted jobs
cat > env_file/prod_env.tfvars << 'EOF'
# Production Environment Configuration for Marketing Analytics Team
dbtcloud_account_id = "12345"
dbtcloud_token      = "your_dbt_cloud_api_token"
dbtcloud_host_url   = "https://cloud.getdbt.com"

# Marketing project ID from platform team
project_id = "102"

# Marketing production environment
environment_id = "311"

team_name = "marketing-team"

EOF

# Append the converted jobs
tail -n +6 converted_marketing_jobs.tfvars >> env_file/prod_env.tfvars

echo "✅ Updated prod_env.tfvars with converted marketing jobs"
```

## 🎯 Phase 3: Marketing-Specific Import Process

### Step 1: Generate Marketing Import Commands

```python
#!/usr/bin/env python3
# generate_marketing_import_commands.py

import json
import os
import re
from pathlib import Path

def get_marketing_category_prefix(job_name):
    """Get category prefix for marketing job organization"""
    name_lower = job_name.lower()
    
    if 'attribution' in name_lower:
        return 'attribution_'
    elif 'campaign' in name_lower:
        return 'campaign_'
    elif any(keyword in name_lower for keyword in ['ltv', 'customer']):
        return 'customer_'
    elif any(keyword in name_lower for keyword in ['executive', 'dashboard']):
        return 'executive_'
    elif any(keyword in name_lower for keyword in ['platform', 'ads']):
        return 'platform_'
    else:
        return ''

def clean_terraform_name(name, team_name):
    """Clean job name for Terraform resource naming (marketing-specific)"""
    # Remove team prefixes
    prefixes_to_remove = [f"{team_name}-", "marketing-team-", "marketing-"]
    
    cleaned_name = name
    for prefix in prefixes_to_remove:
        if cleaned_name.startswith(prefix):
            cleaned_name = cleaned_name[len(prefix):]
    
    # Replace spaces and hyphens with underscores, convert to lowercase
    cleaned = re.sub(r'[-\s]+', '_', cleaned_name.lower())
    # Remove non-alphanumeric characters except underscores
    cleaned = re.sub(r'[^a-z0-9_]', '', cleaned)
    return cleaned

def main():
    discovery_dir = Path("marketing_job_discovery")
    team_name = os.getenv('TEAM_NAME', 'marketing-team')
    
    if not discovery_dir.exists():
        print("❌ Error: Run discover_marketing_jobs.py first")
        return 1
    
    print("🎯 Generating Marketing job import commands...")
    
    try:
        with open(discovery_dir / "production_marketing_jobs.json", 'r') as f:
            production_jobs = json.load(f)
        
        import_commands = []
        
        for job in production_jobs.get('data', []):
            job_id = job['id']
            job_name = job['name']
            
            # Clean up job name for Terraform resource name
            terraform_name = clean_terraform_name(job_name, team_name)
            
            # Add marketing category prefix for organization
            category_prefix = get_marketing_category_prefix(job_name)
            if category_prefix:
                terraform_name = f"{category_prefix}{terraform_name}"
            
            import_command = f"terraform import module.team_jobs.dbtcloud_job.{terraform_name} {job_id}"
            import_commands.append(import_command)
        
        # Save commands to file
        with open("marketing_import_commands.txt", 'w') as f:
            f.write('\n'.join(import_commands))
        
        print("✅ Marketing import commands generated!")
        print("")
        print(f"📊 Generated {len(import_commands)} import commands:")
        for cmd in import_commands:
            print(cmd)
    
    except FileNotFoundError:
        print("❌ Error: production_marketing_jobs.json not found")
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
python generate_marketing_import_commands.py
```

### Step 2: Execute Marketing Job Imports

```python
#!/usr/bin/env python3
# execute_marketing_imports.py

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
    if not Path("marketing_import_commands.txt").exists():
        print("❌ Error: Run generate_marketing_import_commands.py first")
        return 1
    
    print("🎯 Starting Marketing Analytics job import process...")
    print("⚠️  This will import your existing marketing production jobs into Terraform.")
    print("")
    
    # Read import commands
    with open("marketing_import_commands.txt", 'r') as f:
        import_commands = [line.strip() for line in f if line.strip()]
    
    print("📊 Jobs to import:")
    for cmd in import_commands:
        print(cmd)
    print("")
    
    # Confirm with user
    confirm = input(f"Import {len(import_commands)} marketing jobs? (yes/no): ")
    if confirm.lower() != "yes":
        print("❌ Marketing job import cancelled.")
        return 0
    
    # Execute marketing job imports
    print("\n🚀 Importing marketing jobs...")
    for import_cmd in import_commands:
        safe_import(import_cmd)
    
    print("✅ Marketing job import process complete!")
    print("")
    print("🔍 Verifying marketing job imports...")
    
    # Run terraform plan to verify
    try:
        result = subprocess.run(
            ["terraform", "plan", "-var-file=env_file/prod_env.tfvars"],
            check=False
        )
    except Exception as e:
        print(f"❌ Error running terraform plan: {e}")
    
    print("")
    print("📋 Marketing-specific next steps:")
    print("1. Review terraform plan for marketing job configurations")
    print("2. Update any marketing-specific job schedules or settings")
    print("3. Test with staging environment first")
    print("4. Set up marketing attribution validation")
    
    return 0

if __name__ == "__main__":
    exit(main())
```

Run the marketing import:
```bash
python execute_marketing_imports.py
```

## 🧪 Phase 4: Marketing-Specific Testing

### Step 1: Validate Marketing Attribution Jobs

```bash
# Test attribution-specific configurations
echo "🎯 Testing Marketing Attribution Jobs:"
terraform state list | grep attribution

# Validate attribution job schedules (should be early morning)
terraform show module.team_jobs.dbtcloud_job.attribution_daily_refresh | grep -A 5 schedule
```

### Step 2: Test Marketing Campaign Jobs

```bash
# Test campaign performance jobs
echo "📊 Testing Marketing Campaign Jobs:"
terraform state list | grep campaign

# Validate campaign job dependencies (should run after attribution)
```

### Step 3: Test Executive Dashboard Jobs

```bash
# Test executive reporting jobs
echo "📈 Testing Executive Dashboard Jobs:"
terraform state list | grep executive

# Validate executive job timing (should be ready for morning meetings)
```

### Step 4: Test Marketing Development Workflow

```bash
# Test marketing development job creation via API
echo "🧪 Testing Marketing development workflow..."

# Deploy marketing development jobs via API
python scripts/dbt_job_manager.py deploy --config env_file/dev_env.tfvars --dry-run

# Verify marketing job naming for development
echo "Expected naming: marketing-team-{branch}-{user}-{job}"
```

## 📊 Phase 5: Marketing Job Organization

### Step 1: Organize by Marketing Function

Create Python marketing-specific job organization:

```python
#!/usr/bin/env python3
# organize_marketing_jobs.py

import os
from pathlib import Path

def main():
    shared_dev_env_id = os.getenv('SHARED_DEV_ENVIRONMENT_ID', '999')
    staging_env_id = os.getenv('STAGING_ENVIRONMENT_ID', '212')
    prod_env_id = os.getenv('PROD_ENVIRONMENT_ID', '311')
    
    print("📊 Organizing Marketing jobs by function...")
    
    # Environment configuration
    environments = {
        'dev': {
            'env_id': shared_dev_env_id,
            'description': 'Shared dev for branches'
        },
        'test': {
            'env_id': staging_env_id,
            'description': 'Marketing staging'
        },
        'prod': {
            'env_id': prod_env_id,
            'description': 'Marketing production'
        }
    }
    
    # Create organized environment files
    env_file_dir = Path("env_file")
    env_file_dir.mkdir(exist_ok=True)
    
    for env, config in environments.items():
        print(f"Organizing {env} environment...")
        
        # Create organized tfvars file
        organized_content = f"""# {env.title()} Environment - Marketing Analytics Team
# Focus: Attribution, Campaign Performance, Customer LTV, Executive Reporting

dbtcloud_account_id = "12345"
dbtcloud_token      = "your_dbt_cloud_api_token"
project_id          = "102"
environment_id      = "{config['env_id']}"
team_name           = "marketing-team"

jobs = [
  # === MARKETING ATTRIBUTION ===
  {{
    name          = "attribution-daily-refresh"
    description   = "Daily attribution model refresh for marketing analytics"
    execute_steps = ["dbt run --models +attribution+", "dbt test --models +attribution+"]
    schedule_type = "every_day"
    schedule_hours = [6]
    job_type      = "daily"
    threads       = 4
    generate_docs = true
  }},
  
  # === CAMPAIGN PERFORMANCE ===
  {{
    name          = "campaign-performance-analysis"
    description   = "Campaign performance tracking and analysis"
    execute_steps = ["dbt run --models +campaigns+", "dbt test --models +campaigns+"]
    schedule_type = "every_day"
    schedule_hours = [9]
    job_type      = "daily"
    threads       = 4
    generate_docs = true
  }},
  
  # === CUSTOMER LTV ===
  {{
    name          = "customer-ltv-modeling"
    description   = "Customer lifetime value modeling and segmentation"
    execute_steps = ["dbt run --models +customer_ltv+", "dbt test --models +customer_ltv+"]
    schedule_type = "every_day"
    schedule_hours = [12]
    job_type      = "daily"
    threads       = 6
    generate_docs = true
  }},
  
  # === EXECUTIVE REPORTING ===
  {{
    name          = "marketing-executive-dashboard"
    description   = "Executive marketing dashboard and KPI reporting"
    execute_steps = ["dbt run --models +executive+", "dbt test --models +executive+"]
    schedule_type = "every_day"
    schedule_hours = [8]
    job_type      = "daily"
    threads       = 4
    generate_docs = true
  }}
]
"""
        
        # Write organized file
        with open(env_file_dir / f"{env}_env_organized.tfvars", 'w') as f:
            f.write(organized_content)
    
    print("✅ Marketing job organization complete!")
    
    return 0

if __name__ == "__main__":
    exit(main())
```

Run the organization script:
```bash
python organize_marketing_jobs.py
```

### Step 2: Create Marketing Job Schedule Overview

```bash
# Create marketing schedule documentation
cat > MARKETING_SCHEDULE.md << EOF
# Marketing Analytics Job Schedule

## Daily Schedule Overview

### Early Morning (Data Foundation)
- **5:00 AM**: Attribution models (foundation for all marketing analysis)
- **6:00 AM**: Campaign performance data sync

### Morning (Analysis & Reporting)  
- **7:00 AM**: Customer LTV modeling (after attribution)
- **8:00 AM**: Executive dashboard refresh (ready for meetings)
- **9:00 AM**: Campaign performance analysis

### Throughout Day (Real-time Updates)
- **12:00 PM**: Ad platform sync (Facebook, Google, LinkedIn)
- **6:00 PM**: Ad platform sync
- **12:00 AM**: Ad platform sync (3x daily)

### Evening (Validation)
- **9:00 PM**: Data quality validation
- **10:00 PM**: Marketing data monitoring

## Job Dependencies

\`\`\`
Attribution Models
    ↓
Campaign Performance ← Ad Platform Sync
    ↓
Customer LTV Analysis
    ↓  
Executive Dashboards
\`\`\`

## Environment Strategy

- **Development**: All marketing jobs available for testing
- **Staging**: Core marketing validation jobs
- **Production**: Mission-critical marketing analytics only
EOF

echo "📋 Created MARKETING_SCHEDULE.md"
```

## ✅ Marketing-Specific Success Criteria

You'll know the marketing import is successful when:

1. **All marketing production jobs imported**: Attribution, campaign, LTV, executive jobs in Terraform
2. **Marketing schedules optimized**: Attribution runs first, executive dashboards ready for meetings
3. **Platform integration works**: Ad platform sync jobs configured properly
4. **Development workflow functional**: Marketing API job deployment works
5. **Job categorization clear**: Jobs organized by marketing function

## 🎯 Marketing Team Next Steps

After successful import:

1. **Train marketing team** on new hybrid workflow
2. **Set up marketing-specific monitoring** for attribution model drift
3. **Configure executive dashboard SLAs** (99.9% uptime)
4. **Implement marketing data quality alerts** for campaign discrepancies
5. **Schedule regular attribution model validation**

## 📈 Marketing Analytics Benefits

With this setup, your marketing team gets:

- **🎯 Better Attribution**: Reliable, scheduled attribution models
- **📊 Campaign Insights**: Automated cross-platform performance tracking  
- **👥 Customer Intelligence**: Scheduled LTV and segmentation analysis
- **📈 Executive Readiness**: Dashboards ready for morning leadership meetings
- **🔄 Development Agility**: Fast marketing model iteration via API jobs

---

**Congratulations!** Your Marketing Analytics team now has enterprise-grade dbt Cloud job management with marketing-specific optimizations! 🎉