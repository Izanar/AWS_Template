# Usage

## Local control

Set the AWS region and optional budget email either in the environment or in
`envs/<scenario>/terragrunt.hcl`:

```bash
export AWS_DEFAULT_REGION=eu-central-1
export BUDGET_EMAIL=you@example.com   # optional
```

### One-command scenario lifecycle

```bash
./scripts/deploy.sh ec2-dev                  # creates EC2 + nginx + smoke test
./scripts/destroy.sh ec2-dev                 # destroys the same resources

./scripts/deploy.sh eks-fargate-dev          # EKS cluster on AWS
./scripts/deploy.sh eks-ec2-s3-dev           # EKS + S3 + CloudFront
./scripts/deploy.sh local-wsl-dev            # local k3s on WSL2
```

### Individual commands

```bash
make init   ENV=ec2-dev        # terragrunt init
make plan   ENV=ec2-dev        # terragrunt plan
make apply  ENV=ec2-dev        # terragrunt apply (creates resources)
make output ENV=ec2-dev        # print terraform outputs
make destroy ENV=ec2-dev       # terragrunt destroy
```

`make validate` checks Terraform, Ansible, Kubernetes YAML and Shell scripts.

> The EC2 scenario needs an SSH key pair. `public_key_path` defaults to
> `~/.ssh/id_rsa.pub`; the corresponding private key is used by Ansible.

## GitHub Actions

The repository ships two workflows:

- `validate.yml` - runs on every push/PR: `terraform fmt` + `validate`,
  Ansible syntax check, yamllint, shellcheck.
- `deploy.yml` (manual) - choose a scenario and `apply` or `destroy`. Cloud
  scenarios assume an OIDC role announced by the `AWS_ROLE_ARN` secret.

### Required secrets (cloud scenarios)

- `AWS_ROLE_ARN` - role that trusts GitHub OIDC for this repository.
- `AWS_SSH_PRIVATE_KEY` / `AWS_SSH_PUBLIC_KEY` - SSH keys used by the EC2
  Ansible provisioning.

## Budget alerts

Setting `BUDGET_EMAIL` enables an AWS Budget (COST, monthly) alert at 80% of
`monthly_budget_usd` (default 5 USD). AWS Billing permissions are required.
