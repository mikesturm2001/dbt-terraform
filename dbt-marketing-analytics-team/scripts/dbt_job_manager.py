#!/usr/bin/env python3
"""
dbt Cloud Job Manager

This script manages dbt Cloud jobs via the REST API for branch-based deployments.
It handles job creation, updates, and cleanup without Terraform state conflicts.
Reads job configurations directly from Terraform .tfvars files.

Usage:
    python dbt_job_manager.py deploy --config env_file/dev_env.tfvars
    python dbt_job_manager.py cleanup --older-than 7
    python dbt_job_manager.py list --team analytics-team
"""

import os
import sys
import json
import yaml
import requests
import argparse
import re
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Any

class DBTCloudAPI:
    """dbt Cloud REST API client"""
    
    def __init__(self, account_id: str, token: str, host_url: str = "https://cloud.getdbt.com"):
        self.account_id = account_id
        self.token = token
        self.base_url = f"{host_url}/api/v2/accounts/{account_id}"
        self.headers = {
            "Authorization": f"Token {token}",
            "Content-Type": "application/json"
        }
    
    def create_job(self, job_config: Dict[str, Any]) -> Dict[str, Any]:
        """Create a new dbt Cloud job"""
        url = f"{self.base_url}/jobs/"
        
        print(f"Creating job: {job_config['name']}")
        response = requests.post(url, headers=self.headers, json=job_config)
        
        if response.status_code == 201:
            job_data = response.json()['data']
            print(f"✅ Job created successfully - ID: {job_data['id']}")
            return job_data
        else:
            print(f"❌ Failed to create job: {response.status_code} - {response.text}")
            response.raise_for_status()
    
    def update_job(self, job_id: int, job_config: Dict[str, Any]) -> Dict[str, Any]:
        """Update an existing dbt Cloud job"""
        url = f"{self.base_url}/jobs/{job_id}/"
        
        print(f"Updating job: {job_config['name']} (ID: {job_id})")
        response = requests.post(url, headers=self.headers, json=job_config)
        
        if response.status_code == 200:
            job_data = response.json()['data']
            print(f"✅ Job updated successfully - ID: {job_data['id']}")
            return job_data
        else:
            print(f"❌ Failed to update job: {response.status_code} - {response.text}")
            response.raise_for_status()
    
    def delete_job(self, job_id: int) -> bool:
        """Delete a dbt Cloud job"""
        url = f"{self.base_url}/jobs/{job_id}/"
        
        print(f"Deleting job ID: {job_id}")
        response = requests.delete(url, headers=self.headers)
        
        if response.status_code == 204:
            print(f"✅ Job deleted successfully - ID: {job_id}")
            return True
        else:
            print(f"❌ Failed to delete job: {response.status_code} - {response.text}")
            return False
    
    def list_jobs(self, project_id: Optional[int] = None) -> List[Dict[str, Any]]:
        """List all jobs, optionally filtered by project"""
        url = f"{self.base_url}/jobs/"
        if project_id:
            url += f"?project_id={project_id}"
        
        response = requests.get(url, headers=self.headers)
        
        if response.status_code == 200:
            return response.json()['data']
        else:
            print(f"❌ Failed to list jobs: {response.status_code} - {response.text}")
            response.raise_for_status()
    
    def get_job_by_name(self, job_name: str, project_id: Optional[int] = None) -> Optional[Dict[str, Any]]:
        """Find a job by name"""
        jobs = self.list_jobs(project_id)
        for job in jobs:
            if job['name'] == job_name:
                return job
        return None

class JobManager:
    """Manages dbt Cloud jobs for branch deployments"""
    
    def __init__(self):
        # Get configuration from environment variables
        self.account_id = os.getenv('DBTCLOUD_ACCOUNT_ID')
        self.token = os.getenv('DBTCLOUD_TOKEN') 
        self.host_url = os.getenv('DBTCLOUD_HOST_URL', 'https://cloud.getdbt.com')
        self.project_id = int(os.getenv('PROJECT_ID'))
        self.environment_id = int(os.getenv('ENVIRONMENT_ID'))
        
        # GitLab CI variables
        self.team_name = os.getenv('TEAM_NAME', 'analytics-team')
        self.branch_name = os.getenv('CI_COMMIT_REF_SLUG', 'local')
        self.gitlab_user = os.getenv('GITLAB_USER_LOGIN', 'unknown')
        self.commit_sha = os.getenv('CI_COMMIT_SHA', 'unknown')
        
        # Validate required environment variables
        required_vars = ['DBTCLOUD_ACCOUNT_ID', 'DBTCLOUD_TOKEN', 'PROJECT_ID', 'ENVIRONMENT_ID']
        missing_vars = [var for var in required_vars if not os.getenv(var)]
        if missing_vars:
            raise ValueError(f"Missing required environment variables: {missing_vars}")
        
        self.api = DBTCloudAPI(self.account_id, self.token, self.host_url)
        
        print(f"🚀 Job Manager initialized for team: {self.team_name}")
        print(f"   Branch: {self.branch_name}")
        print(f"   User: {self.gitlab_user}")
        print(f"   Environment ID: {self.environment_id}")
    
    def generate_job_name(self, job_base_name: str) -> str:
        """Generate unique job name for branch deployment"""
        # For master/production branches, use simple naming
        if self.branch_name in ['main', 'master', 'production']:
            return f"{self.team_name}-{job_base_name}"
        
        # For feature branches, include branch and user for uniqueness
        return f"{self.team_name}-{self.branch_name}-{self.gitlab_user}-{job_base_name}"
    
    def prepare_job_config(self, job_spec: Dict[str, Any]) -> Dict[str, Any]:
        """Prepare job configuration for dbt Cloud API"""
        job_name = self.generate_job_name(job_spec['name'])
        
        config = {
            "name": job_name,
            "description": f"{job_spec.get('description', '')} (Branch: {self.branch_name}, User: {self.gitlab_user})",
            "project_id": self.project_id,
            "environment_id": self.environment_id,
            "execute_steps": job_spec['execute_steps'],
            "triggers": {
                "github_webhook": False,
                "git_provider_webhook": False,
                "schedule": True,
                "on_merge": False
            },
            "settings": {
                "threads": job_spec.get('threads', 4),
                "target_name": job_spec.get('target_name'),
                "generate_docs": job_spec.get('generate_docs', True),
                "run_generate_sources": job_spec.get('run_generate_sources', False)
            }
        }
        
        # Add schedule configuration
        schedule_config = self._build_schedule_config(job_spec)
        if schedule_config:
            config["schedule"] = schedule_config
        
        # Add tags for branch jobs
        config["tags"] = [
            f"team:{self.team_name}",
            f"branch:{self.branch_name}", 
            f"user:{self.gitlab_user}",
            f"commit:{self.commit_sha[:8]}",
            f"deployed:{datetime.utcnow().isoformat()}"
        ]
        
        return config
    
    def _build_schedule_config(self, job_spec: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """Build schedule configuration from job spec"""
        schedule_type = job_spec.get('schedule_type', 'every_day')
        schedule_hours = job_spec.get('schedule_hours', [])
        schedule_days = job_spec.get('schedule_days', [])
        
        if schedule_type == 'custom' and schedule_hours and schedule_days:
            return {
                "cron": f"0 {','.join(map(str, schedule_hours))} * * {','.join(map(str, schedule_days))}"
            }
        elif schedule_type == 'every_day' and schedule_hours:
            return {
                "days": [1, 2, 3, 4, 5, 6, 7],  # Every day
                "hours": schedule_hours
            }
        elif schedule_type == 'weekly' and schedule_days and schedule_hours:
            return {
                "days": schedule_days,
                "hours": schedule_hours
            }
        
        return None
    
    def parse_tfvars_file(self, tfvars_file: str) -> Dict[str, Any]:
        """Parse a .tfvars file and extract job configurations"""
        print(f"\n📋 Loading job configurations from: {tfvars_file}")
        
        with open(tfvars_file, 'r') as f:
            content = f.read()
        
        # Parse jobs array from tfvars content
        config = {"jobs": []}
        
        # Find the jobs array using bracket matching
        jobs_start = content.find('jobs = [')
        if jobs_start == -1:
            raise ValueError(f"No 'jobs = [' found in {tfvars_file}")
        
        # Find the matching closing bracket
        bracket_count = 0
        jobs_end = -1
        start_pos = jobs_start + len('jobs = [')
        
        for i, char in enumerate(content[start_pos:], start_pos):
            if char == '[':
                bracket_count += 1
            elif char == ']':
                if bracket_count == 0:
                    jobs_end = i
                    break
                bracket_count -= 1
        
        if jobs_end == -1:
            raise ValueError(f"No matching ']' found for jobs array in {tfvars_file}")
        
        jobs_content = content[start_pos:jobs_end]
        
        # Split individual job objects using brace matching
        job_objects = []
        brace_count = 0
        current_job = ""
        in_job = False
        
        for char in jobs_content:
            if char == '{':
                if brace_count == 0:
                    in_job = True
                    current_job = ""
                else:
                    current_job += char
                brace_count += 1
            elif char == '}':
                brace_count -= 1
                if brace_count == 0 and in_job:
                    job_objects.append(current_job)
                    in_job = False
                    current_job = ""
                else:
                    current_job += char
            elif in_job:
                current_job += char
        
        for job_obj in job_objects:
            job = {}
            
            # Parse each field in the job object
            for line in job_obj.split('\n'):
                line = line.strip()
                if not line or line.startswith('#'):
                    continue
                
                # Match field = value patterns
                match = re.match(r'(\w+)\s*=\s*(.+)', line)
                if match:
                    field, value = match.groups()
                    
                    # Remove trailing comma
                    value = value.rstrip(',').strip()
                    
                    # Parse different value types
                    if value.startswith('"') and value.endswith('"'):
                        # String value
                        job[field] = value[1:-1]
                    elif value.startswith('[') and value.endswith(']'):
                        # Array value
                        array_content = value[1:-1]
                        if array_content.strip():
                            # Handle string arrays
                            if '"' in array_content:
                                items = re.findall(r'"([^"]*)"', array_content)
                            else:
                                # Handle number arrays
                                items = [int(x.strip()) for x in array_content.split(',') if x.strip()]
                        else:
                            items = []
                        job[field] = items
                    else:
                        # Try to parse as number
                        try:
                            job[field] = int(value)
                        except ValueError:
                            # Fall back to string (remove quotes if present)
                            job[field] = value.strip('"')
            
            if job:  # Only add non-empty job objects
                config["jobs"].append(job)
        
        print(f"🎯 Found {len(config['jobs'])} job configurations")
        return config

    def deploy_jobs(self, jobs_config_file: str, dry_run: bool = False) -> List[Dict[str, Any]]:
        """Deploy jobs from configuration file (supports .tfvars, .yaml, .json)"""
        
        if jobs_config_file.endswith('.tfvars'):
            config = self.parse_tfvars_file(jobs_config_file)
        else:
            # Keep existing YAML/JSON support for backwards compatibility
            with open(jobs_config_file, 'r') as f:
                if jobs_config_file.endswith('.yaml') or jobs_config_file.endswith('.yml'):
                    config = yaml.safe_load(f)
                else:
                    config = json.load(f)
        
        jobs_spec = config.get('jobs', [])
        deployed_jobs = []
        
        if dry_run:
            print(f"🔍 [DRY RUN] Would deploy {len(jobs_spec)} jobs to environment {self.environment_id}")
            for job_spec in jobs_spec:
                try:
                    job_config = self.prepare_job_config(job_spec)
                    job_name = job_config['name']
                    print(f"  ✅ Job configuration valid: {job_name}")
                except Exception as e:
                    print(f"  ❌ Invalid job configuration for {job_spec.get('name', 'unknown')}: {str(e)}")
            print(f"🔍 [DRY RUN] Configuration validation complete")
            return []
        
        print(f"🎯 Deploying {len(jobs_spec)} jobs to environment {self.environment_id}")
        
        for job_spec in jobs_spec:
            try:
                job_config = self.prepare_job_config(job_spec)
                job_name = job_config['name']
                
                # Check if job already exists
                existing_job = self.api.get_job_by_name(job_name, self.project_id)
                
                if existing_job:
                    # Update existing job
                    job_data = self.api.update_job(existing_job['id'], job_config)
                else:
                    # Create new job
                    job_data = self.api.create_job(job_config)
                
                deployed_jobs.append(job_data)
                
            except Exception as e:
                print(f"❌ Failed to deploy job {job_spec['name']}: {str(e)}")
                continue
        
        print(f"\n✅ Successfully deployed {len(deployed_jobs)} jobs")
        return deployed_jobs
    
    def cleanup_old_jobs(self, days_old: int = 7, dry_run: bool = False) -> List[int]:
        """Clean up branch jobs older than specified days"""
        print(f"\n🧹 Cleaning up branch jobs older than {days_old} days")
        
        all_jobs = self.api.list_jobs(self.project_id)
        cutoff_date = datetime.utcnow() - timedelta(days=days_old)
        
        jobs_to_delete = []
        
        for job in all_jobs:
            job_name = job['name']
            
            # Only clean up branch jobs (contain branch and user in name)
            if not self._is_branch_job(job_name):
                continue
            
            # Check if job is old enough
            job_created = datetime.fromisoformat(job['created_at'].replace('Z', '+00:00'))
            if job_created.replace(tzinfo=None) > cutoff_date:
                continue
            
            jobs_to_delete.append(job)
        
        print(f"🎯 Found {len(jobs_to_delete)} jobs to clean up")
        
        deleted_job_ids = []
        
        for job in jobs_to_delete:
            if dry_run:
                print(f"[DRY RUN] Would delete: {job['name']} (ID: {job['id']}, Created: {job['created_at']})")
            else:
                if self.api.delete_job(job['id']):
                    deleted_job_ids.append(job['id'])
        
        if dry_run:
            print(f"\n[DRY RUN] Would delete {len(jobs_to_delete)} jobs")
        else:
            print(f"\n✅ Successfully deleted {len(deleted_job_ids)} jobs")
        
        return deleted_job_ids
    
    def _is_branch_job(self, job_name: str) -> bool:
        """Check if job name indicates it's a branch job"""
        # Branch jobs have format: team-branch-user-job
        # Production jobs have format: team-job
        parts = job_name.split('-')
        
        # If job has more than 2 parts and doesn't start with team-main or team-master
        if len(parts) > 2 and not (len(parts) == 2 or 
                                  job_name.startswith(f"{self.team_name}-main-") or
                                  job_name.startswith(f"{self.team_name}-master-") or
                                  job_name.startswith(f"{self.team_name}-production-")):
            return True
        
        return False
    
    def list_team_jobs(self, show_details: bool = False) -> List[Dict[str, Any]]:
        """List all jobs for this team"""
        print(f"\n📋 Listing jobs for team: {self.team_name}")
        
        all_jobs = self.api.list_jobs(self.project_id)
        team_jobs = [job for job in all_jobs if job['name'].startswith(f"{self.team_name}-")]
        
        branch_jobs = []
        production_jobs = []
        
        for job in team_jobs:
            if self._is_branch_job(job['name']):
                branch_jobs.append(job)
            else:
                production_jobs.append(job)
        
        print(f"\n🏭 Production Jobs ({len(production_jobs)}):")
        for job in production_jobs:
            status = "✅ Active" if job.get('state') == 1 else "❌ Inactive"
            print(f"  - {job['name']} (ID: {job['id']}) - {status}")
            if show_details:
                print(f"    Environment: {job.get('environment_id')}")
                print(f"    Created: {job.get('created_at')}")
        
        print(f"\n🌿 Branch Jobs ({len(branch_jobs)}):")
        for job in branch_jobs:
            status = "✅ Active" if job.get('state') == 1 else "❌ Inactive"
            print(f"  - {job['name']} (ID: {job['id']}) - {status}")
            if show_details:
                print(f"    Created: {job.get('created_at')}")
        
        return team_jobs

def main():
    parser = argparse.ArgumentParser(description='dbt Cloud Job Manager')
    subparsers = parser.add_subparsers(dest='command', help='Commands')
    
    # Deploy command
    deploy_parser = subparsers.add_parser('deploy', help='Deploy jobs from config file')
    deploy_parser.add_argument('--config', required=True, help='Path to jobs configuration file (.tfvars, .yaml, or .json)')
    deploy_parser.add_argument('--dry-run', action='store_true', help='Validate configuration without deploying')
    
    # Cleanup command
    cleanup_parser = subparsers.add_parser('cleanup', help='Clean up old branch jobs')
    cleanup_parser.add_argument('--older-than', type=int, default=7, help='Delete jobs older than N days (default: 7)')
    cleanup_parser.add_argument('--dry-run', action='store_true', help='Show what would be deleted without actually deleting')
    
    # List command
    list_parser = subparsers.add_parser('list', help='List team jobs')
    list_parser.add_argument('--details', action='store_true', help='Show detailed job information')
    
    args = parser.parse_args()
    
    if not args.command:
        parser.print_help()
        sys.exit(1)
    
    try:
        manager = JobManager()
        
        if args.command == 'deploy':
            manager.deploy_jobs(args.config, args.dry_run)
        
        elif args.command == 'cleanup':
            manager.cleanup_old_jobs(args.older_than, args.dry_run)
        
        elif args.command == 'list':
            manager.list_team_jobs(args.details)
            
    except Exception as e:
        print(f"❌ Error: {str(e)}")
        sys.exit(1)

if __name__ == "__main__":
    main()