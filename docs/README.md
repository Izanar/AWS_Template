# ImageTestEnv documentation

Welcome to the ImageTestEnv documentation. This project is a hands-on,
reusable infrastructure template that demonstrates the same demo application
deployed with four different setups:

| Scenario | Infrastructure | Applies to |
|---|---|---|
| `ec2-dev` | AWS Spot EC2 + nginx, configured with Ansible | Cloud (AWS) |
| `eks-fargate-dev` | AWS EKS cluster (Fargate profiles) | Cloud (AWS) |
| `eks-ec2-s3-dev` | AWS EKS + S3 + CloudFront with OAC | Cloud (AWS) |
| `local-wsl-dev` | k3s on WSL2, no cloud required | Local (WSL2) |

Terraform defines the infrastructure, Terragrunt supplies per-environment
values, Ansible configures the running servers/clusters, and Kubernetes
manifests describe the deployed workload.

## Table of contents

- [Architecture](architecture.md) - repository layout and data flow
- [Usage](usage.md) - local control, CI/CD, requirements
- [Development](development.md) - validation, testing, contributing

## Prerequisites

- Terraform `>= 1.9.0`
- Terragrunt `>= 0.68.0`
- Ansible `core 2.15+` (only for `ec2-dev` / EKS deploys)
- AWS CLI (only for cloud scenarios)

`make install-tools` installs Terraform, Terragrunt and the Python tooling
into `~/.local/bin` and `~/venvs/tools` (latest releases).
