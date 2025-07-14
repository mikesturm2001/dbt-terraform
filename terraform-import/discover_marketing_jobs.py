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