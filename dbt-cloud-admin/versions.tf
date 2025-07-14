terraform {
  required_version = ">= 1.3"
  
  required_providers {
    dbtcloud = {
      source  = "dbt-labs/dbtcloud"
      version = "~> 0.3"
    }
  }

  backend "gitlab" {
    # Configuration will be provided via backend-config files
  }
}

provider "dbtcloud" {
  account_id = var.dbtcloud_account_id
  token      = var.dbtcloud_token
  host_url   = var.dbtcloud_host_url
}