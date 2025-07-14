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
    # Check for different import command files
    marketing_commands = Path("marketing_import_commands.txt")
    analytics_commands = Path("job_import_commands.txt")
    
    if marketing_commands.exists():
        commands_file = marketing_commands
        team_type = "marketing"
    elif analytics_commands.exists():
        commands_file = analytics_commands
        team_type = "analytics"
    else:
        print("❌ Error: Run generate_job_import_commands.py first")
        return 1
    
    print(f"🚀 Starting {team_type} job import process...")
    print("⚠️  This will import your existing production jobs into Terraform management.")
    print("")
    
    # Read import commands
    with open(commands_file, 'r') as f:
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