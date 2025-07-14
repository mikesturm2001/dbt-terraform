# dbt Marketing Analytics Team - Job Management

This repository manages dbt Cloud jobs for the Marketing Analytics Team using a **hybrid deployment approach**:

- 🌿 **Branch Jobs**: API-based deployment to shared `terraform-dev` environment
- 🏭 **Production Jobs**: Terraform-based deployment to dedicated environments

## 🎯 Marketing Analytics Focus Areas

Our dbt jobs are designed to support comprehensive marketing analytics:

### 📊 **Attribution & Performance**
- Multi-touch attribution modeling
- Campaign performance tracking
- Cross-channel marketing analysis
- ROI and ROAS calculations

### 👥 **Customer Analytics**
- Customer acquisition funnel analysis
- Lifetime value (LTV) modeling
- Customer segmentation
- Cohort analysis

### 📱 **Platform Integration**
- Facebook/Meta Ads integration
- Google Ads and Analytics sync
- LinkedIn Ads performance
- Email marketing automation metrics

### 📈 **Executive Reporting**
- Marketing KPI dashboards
- Executive summary reports
- Budget vs. performance analysis
- Attribution reporting for leadership

## 🏗️ Architecture Overview

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Feature       │    │   dbt Cloud      │    │  Shared Dev     │
│   Branches      │───▶│   REST API       │───▶│  Environment    │
│                 │    │                  │    │                 │
└─────────────────┘    └──────────────────┘    └─────────────────┘

┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│ Main/Staging/   │    │   Terraform      │    │ Marketing Team  │
│ Production      │───▶│   Provider       │───▶│ Environments    │
│                 │    │                  │    │                 │
└─────────────────┘    └──────────────────┘    └─────────────────┘
```

## 📁 Repository Structure

```
dbt-marketing-analytics-team/
├── scripts/
│   └── dbt_job_manager.py          # Python API client for job management
├── env_file/
│   ├── dev_env.tfvars              # Development environment config & jobs
│   ├── test_env.tfvars             # Test environment config & jobs
│   └── prod_env.tfvars             # Production environment config & jobs
├── requirements.txt                # Python dependencies
├── .gitlab-ci.yml                 # CI/CD pipeline
├── main.tf                        # Terraform configuration (production)
├── variables.tf                   # Terraform variables
└── README.md                      # This file
```

## 🚀 Quick Start

### 1. Configure Environment Variables

Set these in your GitLab CI/CD settings:

```bash
# Required for all deployments
DBTCLOUD_ACCOUNT_ID=12345
DBTCLOUD_TOKEN=your-api-token-here
PROJECT_ID=102                      # Marketing project ID from platform team
ENVIRONMENT_ID=999                  # Shared dev environment ID

# Optional
DBTCLOUD_HOST_URL=https://cloud.getdbt.com  # Default
TEAM_NAME=marketing-team                    # Default
```

### 2. Deploy Branch Jobs (Development)

1. Create a feature branch: `git checkout -b feature/attribution-model-v2`
2. Modify job configurations in `env_file/dev_env.tfvars`
3. Push changes and create merge request
4. Manually trigger `deploy-branch-jobs` in GitLab CI

**Result**: Jobs deployed to shared dev environment with naming pattern:
```
marketing-team-feature-attribution-model-v2-jennifer-lopez-attribution-daily-refresh
marketing-team-feature-attribution-model-v2-jennifer-lopez-campaign-performance
```

### 3. Deploy Production Jobs

1. Merge to `main` branch (deploys to staging environment)
2. Merge to `production` branch (deploys to prod environment)
3. Manually trigger `deploy-production-terraform` in GitLab CI

**Result**: Jobs deployed via Terraform with naming pattern:
```
marketing-team-attribution-production
marketing-team-campaign-performance-production
```

## 📋 Marketing Job Categories

### 🎯 Attribution Jobs
- **`attribution-daily-refresh`**: Core attribution models
- **`attribution-validation`**: Attribution model testing

### 📊 Campaign Jobs  
- **`campaign-performance`**: Campaign tracking and metrics
- **`ad-platform-sync`**: Multi-platform ad data integration

### 👥 Customer Jobs
- **`customer-acquisition-funnel`**: Funnel analysis
- **`customer-ltv-modeling`**: Lifetime value calculations

### 📧 Marketing Automation
- **`email-marketing-metrics`**: Email campaign performance
- **`automation-flows`**: Marketing automation tracking

### 📈 Executive Reporting
- **`marketing-executive-dashboard`**: C-level marketing KPIs
- **`executive-dashboard-production`**: Production executive reports

## 🔧 Environment Configuration

### **Development Environment** (`dev_env.tfvars`)
- **9 jobs** including development and testing jobs
- **Shared Environment**: Uses platform team's shared dev environment
- **Schedule**: Flexible, development-friendly times (8 AM - 1 PM)
- **Features**: Ad platform sync every 6 hours, on-demand testing

### **Test Environment** (`test_env.tfvars`)
- **6 jobs** focused on validation and testing
- **Environment**: Marketing staging environment
- **Schedule**: Early morning testing cycle (7 AM - 11 AM)
- **Features**: Business logic validation, integration testing

### **Production Environment** (`prod_env.tfvars`)
- **5 jobs** for business-critical workloads
- **Environment**: Marketing production environment
- **Schedule**: Very early morning (5 AM - 8 AM)
- **Features**: Executive reporting, critical data validation

## 🌍 Platform Team Integration

This project integrates with the central `dbt-cloud-admin` infrastructure:

### **Project Reference**
```hcl
# From platform team output: marketing_project.project_id
project_id = "102"
```

### **Environment References**
```hcl
# Development (shared across all teams)
shared_dev_environment_id = "999"

# Marketing-specific environments
marketing_staging_environment_id = "202" 
marketing_production_environment_id = "302"
```

## 🛠️ Local Development

### Prerequisites
- Python 3.9+
- dbt Cloud API access
- Marketing team permissions

### Setup
```bash
# Install dependencies
pip install -r requirements.txt

# Set environment variables
export DBTCLOUD_ACCOUNT_ID=12345
export DBTCLOUD_TOKEN=your-token
export PROJECT_ID=102                    # Marketing project ID
export ENVIRONMENT_ID=999                # Shared dev environment
export TEAM_NAME=marketing-team
export CI_COMMIT_REF_SLUG=local-dev
export GITLAB_USER_LOGIN=your-username
```

### Commands
```bash
# Deploy jobs locally
python scripts/dbt_job_manager.py deploy --config env_file/dev_env.tfvars

# Validate configuration without deploying
python scripts/dbt_job_manager.py deploy --config env_file/dev_env.tfvars --dry-run

# List team jobs
python scripts/dbt_job_manager.py list --details

# Clean up old jobs
python scripts/dbt_job_manager.py cleanup --older-than 7 --dry-run
```

## 🔄 Job Scheduling Strategy

### **Development Jobs**
- **Attribution**: 8 AM (after overnight data loads)
- **Campaigns**: 9 AM (after attribution)
- **Ad Platforms**: 6 AM, 12 PM, 6 PM (3x daily sync)
- **Customer LTV**: 12 PM (midday analysis)
- **Executive Dashboard**: 1 PM (after LTV)

### **Production Jobs**
- **Attribution**: 5 AM (very early)
- **Campaigns**: 6 AM (after attribution)
- **Customer LTV**: 7 AM (after campaigns)
- **Executive Dashboard**: 8 AM (ready for morning meetings)
- **Critical Tests**: 9 AM & 9 PM (twice daily validation)

## 🔍 Monitoring & Debugging

### Marketing-Specific Monitoring
- **Attribution Model Drift**: Monitor attribution coefficients
- **Campaign Data Freshness**: Ensure ad platform data is current
- **LTV Model Performance**: Track prediction accuracy
- **Executive Dashboard SLAs**: 99.9% uptime for leadership reports

### Common Marketing Data Issues

#### Issue: Attribution Model Inconsistencies
**Solution**: Check ad platform API rate limits and data completeness tests

#### Issue: Campaign ROI Discrepancies  
**Solution**: Verify cost data imports and attribution window settings

#### Issue: Customer LTV Calculations Off
**Solution**: Validate customer lifecycle stage mappings and revenue recognition

## 🔐 Data Security & Compliance

### Marketing Data Governance
- **PII Handling**: Customer data anonymized in attribution models
- **Ad Platform Tokens**: Stored securely in GitLab CI variables
- **GDPR Compliance**: Customer opt-out handling in LTV models
- **Attribution Windows**: Configurable for privacy compliance

## 🚀 Advanced Features

### **Multi-Touch Attribution**
Jobs support various attribution models:
- First-touch attribution
- Last-touch attribution  
- Linear attribution
- Time-decay attribution
- Position-based attribution

### **Cross-Platform Integration**
Automated data sync from:
- Facebook/Meta Ads Manager
- Google Ads & Analytics
- LinkedIn Campaign Manager
- Email platforms (SendGrid, Mailchimp)
- Marketing automation tools

### **Customer Segmentation**
Advanced segmentation models:
- RFM analysis (Recency, Frequency, Monetary)
- Behavioral cohorts
- Predictive segments
- Lookalike modeling

## 🤝 Contributing

1. Create feature branch: `git checkout -b feature/new-attribution-model`
2. Modify job configurations in `env_file/dev_env.tfvars`
3. Test changes in your branch deployment
4. Create merge request with marketing team review
5. After approval, production deployment happens automatically

## 📚 Additional Resources

### Marketing Analytics Documentation
- [Marketing Attribution Models](internal-docs/attribution-models.md)
- [Campaign Performance Tracking](internal-docs/campaign-tracking.md)
- [Customer LTV Methodology](internal-docs/ltv-calculations.md)

### Related Repositories
- `dbt-cloud-admin`: Infrastructure and environment management
- `dbt-marketing-models`: Marketing dbt models and transformations
- `marketing-data-pipelines`: Data ingestion and ETL pipelines

---

**Team**: Marketing Analytics Team  
**Maintained by**: Marketing Data Engineering  
**Last Updated**: 2024-12-11