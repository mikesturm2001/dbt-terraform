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
    
    # Remove other common prefixes
    for prefix in ["marketing-team-", "marketing-", "analytics-team-", "analytics-"]:
        if name.startswith(prefix):
            name = name[len(prefix):]
    
    # Replace spaces and hyphens with underscores, convert to lowercase
    cleaned = re.sub(r'[-\s]+', '_', name.lower())
    # Remove non-alphanumeric characters except underscores
    cleaned = re.sub(r'[^a-z0-9_]', '', cleaned)
    return cleaned

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

def main():
    # Check for both analytics and marketing job discovery directories
    analytics_discovery_dir = Path("job_discovery")
    marketing_discovery_dir = Path("marketing_job_discovery")
    team_name = os.getenv('TEAM_NAME', 'analytics-team')
    
    # Determine which discovery directory to use
    if marketing_discovery_dir.exists():
        discovery_dir = marketing_discovery_dir
        production_file = "production_marketing_jobs.json"
        team_type = "marketing"
        output_file = "marketing_import_commands.txt"
        use_category_prefix = True
    elif analytics_discovery_dir.exists():
        discovery_dir = analytics_discovery_dir
        production_file = "production_jobs.json"
        team_type = "analytics"
        output_file = "job_import_commands.txt"
        use_category_prefix = False
    else:
        print("❌ Error: Run discover_team_jobs.py or discover_marketing_jobs.py first")
        return 1
    
    print(f"🔧 Generating Terraform import commands for {team_type} production jobs...")
    
    try:
        with open(discovery_dir / production_file, 'r') as f:
            production_jobs = json.load(f)
        
        import_commands = []
        
        for job in production_jobs.get('data', []):
            job_id = job['id']
            job_name = job['name']
            
            # Clean up job name for Terraform resource name
            terraform_name = clean_terraform_name(job_name, team_name)
            
            # Add category prefix for marketing jobs
            if use_category_prefix:
                category_prefix = get_marketing_category_prefix(job_name)
                if category_prefix:
                    terraform_name = f"{category_prefix}{terraform_name}"
            
            import_command = f"terraform import module.team_jobs.dbtcloud_job.{terraform_name} {job_id}"
            import_commands.append(import_command)
        
        # Save commands to file
        with open(output_file, 'w') as f:
            f.write('\n'.join(import_commands))
        
        print(f"✅ Import commands generated in {output_file}")
        print("")
        print(f"Generated {len(import_commands)} import commands:")
        for cmd in import_commands:
            print(cmd)
    
    except FileNotFoundError:
        print(f"❌ Error: {production_file} not found")
        return 1
    except Exception as e:
        print(f"❌ Error generating import commands: {e}")
        return 1
    
    return 0

if __name__ == "__main__":
    exit(main())