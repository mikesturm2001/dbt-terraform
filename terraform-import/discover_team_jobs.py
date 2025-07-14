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