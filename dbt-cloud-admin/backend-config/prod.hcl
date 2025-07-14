# Backend configuration for production environment
address = "https://gitlab.example.com/api/v4/projects/PROJECT_ID/terraform/state/prod"
lock_address = "https://gitlab.example.com/api/v4/projects/PROJECT_ID/terraform/state/prod/lock"
unlock_address = "https://gitlab.example.com/api/v4/projects/PROJECT_ID/terraform/state/prod/lock"
username = "gitlab-ci-token"
password = "${CI_JOB_TOKEN}"
lock_method = "POST"
unlock_method = "DELETE"
retry_wait_min = 5