#!/usr/bin/env python3
# convert_jobs_to_tfvars.py

import json
import os
from pathlib import Path
from datetime import datetime

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
    elif analytics_discovery_dir.exists():
        discovery_dir = analytics_discovery_dir
        production_file = "production_jobs.json"
        team_type = "analytics"
    else:
        print("❌ Error: Run discover_team_jobs.py or discover_marketing_jobs.py first")
        return 1
    
    print(f"🔄 Converting {team_type} production jobs to tfvars format...")
    
    try:
        with open(discovery_dir / production_file, 'r') as f:
            production_jobs = json.load(f)
        
        # Start building tfvars content
        tfvars_content = [
            f"# Converted from existing dbt Cloud {team_type} jobs",
            f"# Generated on: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}",
            "",
            "jobs = ["
        ]
        
        for job in production_jobs.get('data', []):
            # Clean job name (remove team prefix if present)
            job_name = job['name']
            if job_name.startswith(f"{team_name}-"):
                job_name = job_name[len(team_name)+1:]
            
            description = job.get('description') or f"Imported from existing dbt Cloud {team_type} job"
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
        with open(f"converted_{team_type}_jobs.tfvars", 'w') as f:
            f.write('\n'.join(tfvars_content))
        
        print(f"✅ Conversion complete! Check converted_{team_type}_jobs.tfvars")
        print("")
        print("📝 Next steps:")
        print(f"1. Review converted_{team_type}_jobs.tfvars")
        print("2. Update your env_file/prod_env.tfvars with these jobs")
        print("3. Test the configuration with --dry-run")
        
    except FileNotFoundError:
        print(f"❌ Error: {production_file} not found")
        return 1
    except Exception as e:
        print(f"❌ Error during conversion: {e}")
        return 1
    
    return 0

if __name__ == "__main__":
    exit(main())