include "root" {
  path = find_in_parent_folders()
}

inputs = {
  project_name      = "image-test-env"
  environment       = "dev"
  aws_region        = get_env("AWS_DEFAULT_REGION", "eu-central-1")
  kubernetes_version = "v1.31.1+k3s1"
  node_port         = 30080
}