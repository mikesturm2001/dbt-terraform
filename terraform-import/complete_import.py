#!/usr/bin/env python3
# complete_import.py

import os
import json
import subprocess
import sys
from pathlib import Path

def safe_import(resource, resource_id):
    """Safely import a resource, ignoring errors if already imported"""
    print(f"Importing {resource} with ID {resource_id}...")
    try:
        result = subprocess.run(
            ["terraform", "import", resource, str(resource_id)],
            capture_output=True,
            text=True,
            check=False
        )
        if result.returncode == 0:
            print(f"  ✅ Successfully imported {resource}")
        else:
            print(f"  ⚠️  Already imported or failed: {resource}")
    except Exception as e:
        print(f"  ❌ Error importing {resource}: {e}")

def clean_name(name):
    """Clean name for Terraform resource naming"""
    import re
    # Replace spaces and hyphens with underscores, convert to lowercase
    cleaned = re.sub(r'[-\s]+', '_', name.lower())
    # Remove non-alphanumeric characters except underscores
    cleaned = re.sub(r'[^a-z0-9_]', '', cleaned)
    return cleaned

def main():
    print("🚀 Starting complete dbt Cloud import process...")
    
    # Verify environment variables
    account_id = os.getenv('DBTCLOUD_ACCOUNT_ID')
    token = os.getenv('DBTCLOUD_TOKEN')
    
    if not account_id or not token:
        print("❌ Error: DBTCLOUD_ACCOUNT_ID and DBTCLOUD_TOKEN must be set")
        return 1
    
    discovery_dir = Path("dbt_discovery")
    if not discovery_dir.exists():
        print("❌ Error: Run discover_dbt_resources.py first")
        return 1
    
    # Initialize Terraform
    print("🔧 Initializing Terraform...")
    try:
        subprocess.run(["terraform", "init"], check=True)
    except subprocess.CalledProcessError as e:
        print(f"❌ Failed to initialize Terraform: {e}")
        return 1
    
    # Import Projects
    print("📁 Importing Projects...")
    try:
        with open(discovery_dir / "projects.json", 'r') as f:
            projects = json.load(f)
        
        for project in projects.get('data', []):
            resource_name = clean_name(project['name'])
            safe_import(f"dbtcloud_project.{resource_name}", project['id'])
    except FileNotFoundError:
        print("⚠️  No projects.json found")
    
    # Import Environments
    print("🌍 Importing Environments...")
    try:
        with open(discovery_dir / "environments.json", 'r') as f:
            environments = json.load(f)
        
        for env in environments.get('data', []):
            resource_name = clean_name(env['name'])
            safe_import(f"dbtcloud_environment.{resource_name}", env['id'])
    except FileNotFoundError:
        print("⚠️  No environments.json found")
    
    # Import Connections
    print("🔗 Importing Connections...")
    try:
        with open(discovery_dir / "connections.json", 'r') as f:
            connections = json.load(f)
        
        for conn in connections.get('data', []):
            resource_name = clean_name(conn['name'])
            conn_type = "snowflake_connection" if conn['type'] == 'snowflake' else "connection"
            safe_import(f"dbtcloud_{conn_type}.{resource_name}", conn['id'])
    except FileNotFoundError:
        print("⚠️  No connections.json found")
    
    # Import Users
    print("👥 Importing Users...")
    try:
        with open(discovery_dir / "users.json", 'r') as f:
            users = json.load(f)
        
        for user in users.get('data', []):
            first_name = clean_name(user.get('first_name', 'user'))
            last_name = clean_name(user.get('last_name', 'name'))
            resource_name = f"{first_name}_{last_name}"
            safe_import(f"dbtcloud_user.{resource_name}", user['id'])
    except FileNotFoundError:
        print("⚠️  No users.json found")
    
    # Import Groups
    print("🏢 Importing Groups...")
    try:
        with open(discovery_dir / "groups.json", 'r') as f:
            groups = json.load(f)
        
        for group in groups.get('data', []):
            resource_name = clean_name(group['name'])
            safe_import(f"dbtcloud_group.{resource_name}", group['id'])
    except FileNotFoundError:
        print("⚠️  No groups.json found")
    
    print("✅ Import process complete!")
    print("📋 Next steps:")
    print("1. Run 'terraform plan' to see any configuration drift")
    print("2. Update your main.tf to match existing resources exactly")
    print("3. Run 'terraform plan' again until it shows 'No changes'")
    print("4. You're ready to manage your dbt Cloud infrastructure with Terraform!")
    
    return 0

if __name__ == "__main__":
    exit(main())