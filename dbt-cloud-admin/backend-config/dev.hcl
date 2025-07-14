# Backend configuration for development environment
address = "https://gitlab.example.com/api/v4/projects/PROJECT_ID/terraform/state/dev"
lock_address = "https://gitlab.example.com/api/v4/projects/PROJECT_ID/terraform/state/dev/lock"
unlock_address = "https://gitlab.example.com/api/v4/projects/PROJECT_ID/terraform/state/dev/lock"
username = "gitlab-ci-token"
password = "${CI_JOB_TOKEN}"
lock_method = "POST"
unlock_method = "DELETE"
retry_wait_min = 5