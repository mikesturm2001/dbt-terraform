#!/usr/bin/env python3
# discover_dbt_resources.py

import os
import json
import requests
from pathlib import Path

def main():
    # Get environment variables
    account_id = os.getenv('DBTCLOUD_ACCOUNT_ID')
    token = os.getenv('DBTCLOUD_TOKEN')
    host_url = os.getenv('DBTCLOUD_HOST_URL', 'https://cloud.getdbt.com')
    
    if not account_id or not token:
        print("❌ Error: DBTCLOUD_ACCOUNT_ID and DBTCLOUD_TOKEN must be set")
        return 1
    
    print("🔍 Discovering your dbt Cloud resources...")
    print(f"Account ID: {account_id}")
    print(f"Host: {host_url}")
    print("")
    
    base_url = f"{host_url}/api/v2/accounts/{account_id}"
    headers = {"Authorization": f"Token {token}"}
    
    # Create output directory
    output_dir = Path("dbt_discovery")
    output_dir.mkdir(exist_ok=True)
    
    # Resource types to discover
    resources = {
        "projects": "📁 Getting Projects...",
        "environments": "🌍 Getting Environments...",
        "connections": "🔗 Getting Connections...",
        "users": "👥 Getting Users...",
        "groups": "🏢 Getting Groups...",
        "repositories": "📚 Getting Repositories..."
    }
    
    for resource, message in resources.items():
        print(message)
        try:
            response = requests.get(f"{base_url}/{resource}/", headers=headers)
            response.raise_for_status()
            data = response.json()
            
            # Save to file
            with open(output_dir / f"{resource}.json", 'w') as f:
                json.dump(data, f, indent=2)
            
            count = len(data.get('data', []))
            print(f"Found {count} {resource}")
            
        except requests.exceptions.RequestException as e:
            print(f"❌ Error fetching {resource}: {e}")
        
        print("")
    
    print("✅ Discovery complete! Check the dbt_discovery/ folder for details.")
    print("💡 Tip: Review these files to understand your current setup before importing.")
    
    return 0

if __name__ == "__main__":
    exit(main())