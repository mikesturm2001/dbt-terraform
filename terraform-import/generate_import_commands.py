#!/usr/bin/env python3
# generate_import_commands.py

import os
import json
import requests
import re
from pathlib import Path

def clean_name(name):
    """Clean name for Terraform resource naming"""
    # Replace spaces and hyphens with underscores, convert to lowercase
    cleaned = re.sub(r'[-\s]+', '_', name.lower())
    # Remove non-alphanumeric characters except underscores
    cleaned = re.sub(r'[^a-z0-9_]', '', cleaned)
    return cleaned

def main():
    # Get environment variables
    account_id = os.getenv('DBTCLOUD_ACCOUNT_ID')
    token = os.getenv('DBTCLOUD_TOKEN')
    host_url = os.getenv('DBTCLOUD_HOST_URL', 'https://cloud.getdbt.com')
    
    if not account_id or not token:
        print("❌ Error: DBTCLOUD_ACCOUNT_ID and DBTCLOUD_TOKEN must be set")
        return 1
    
    print("🔧 Generating Terraform import commands...")
    print("")
    
    base_url = f"{host_url}/api/v2/accounts/{account_id}"
    headers = {"Authorization": f"Token {token}"}
    discovery_dir = Path("dbt_discovery")
    
    commands = []
    
    # Generate project imports
    commands.append("# ===== PROJECT IMPORTS =====")
    try:
        with open(discovery_dir / "projects.json", 'r') as f:
            projects = json.load(f)
        
        for project in projects.get('data', []):
            resource_name = clean_name(project['name'])
            commands.append(f"terraform import dbtcloud_project.{resource_name} {project['id']}")
    except FileNotFoundError:
        print("Warning: No projects.json found")
    
    commands.append("")
    
    # Generate environment imports
    commands.append("# ===== ENVIRONMENT IMPORTS =====")
    try:
        with open(discovery_dir / "environments.json", 'r') as f:
            environments = json.load(f)
        
        for env in environments.get('data', []):
            resource_name = clean_name(env['name'])
            commands.append(f"terraform import dbtcloud_environment.{resource_name} {env['id']}")
    except FileNotFoundError:
        print("Warning: No environments.json found")
    
    commands.append("")
    
    # Generate connection imports
    commands.append("# ===== CONNECTION IMPORTS =====")
    try:
        with open(discovery_dir / "connections.json", 'r') as f:
            connections = json.load(f)
        
        for conn in connections.get('data', []):
            resource_name = clean_name(conn['name'])
            conn_type = "snowflake_connection" if conn['type'] == 'snowflake' else "connection"
            commands.append(f"terraform import dbtcloud_{conn_type}.{resource_name} {conn['id']}")
    except FileNotFoundError:
        print("Warning: No connections.json found")
    
    commands.append("")
    
    # Generate user imports
    commands.append("# ===== USER IMPORTS =====")
    try:
        with open(discovery_dir / "users.json", 'r') as f:
            users = json.load(f)
        
        for user in users.get('data', []):
            first_name = clean_name(user.get('first_name', 'user'))
            last_name = clean_name(user.get('last_name', 'name'))
            resource_name = f"{first_name}_{last_name}"
            commands.append(f"terraform import dbtcloud_user.{resource_name} {user['id']}")
    except FileNotFoundError:
        print("Warning: No users.json found")
    
    commands.append("")
    
    # Generate group imports
    commands.append("# ===== GROUP IMPORTS =====")
    try:
        with open(discovery_dir / "groups.json", 'r') as f:
            groups = json.load(f)
        
        for group in groups.get('data', []):
            resource_name = clean_name(group['name'])
            commands.append(f"terraform import dbtcloud_group.{resource_name} {group['id']}")
    except FileNotFoundError:
        print("Warning: No groups.json found")
    
    commands.append("")
    
    # Generate repository imports
    commands.append("# ===== REPOSITORY IMPORTS =====")
    try:
        with open(discovery_dir / "repositories.json", 'r') as f:
            repositories = json.load(f)
        
        for repo in repositories.get('data', []):
            # Extract repo name from URL
            remote_url = repo.get('remote_url', '')
            if remote_url:
                repo_name = remote_url.split('/')[-1].replace('.git', '')
                resource_name = clean_name(repo_name)
            else:
                resource_name = f"repo_{repo['id']}"
            commands.append(f"terraform import dbtcloud_repository.{resource_name} {repo['id']}")
    except FileNotFoundError:
        print("Warning: No repositories.json found")
    
    # Save commands to file
    with open("import_commands.txt", 'w') as f:
        f.write('\n'.join(commands))
    
    print("✅ Import commands generated!")
    print(f"📁 Saved to: import_commands.txt")
    print(f"📊 Generated {len([c for c in commands if c.startswith('terraform')])} import commands")
    
    return 0

if __name__ == "__main__":
    exit(main())