# ImageTestEnv

A hands-on infrastructure template that deploys the same demo application
through four different setups using **Terraform**, **Terragrunt**, **Ansible**
and **Kubernetes**.

| Scenario | Infrastructure | Where |
|---|---|---|
| `ec2-dev` | AWS Spot EC2 + nginx (Ansible) | Cloud (AWS) |
| `eks-fargate-dev` | AWS EKS cluster (Fargate profiles) | Cloud (AWS) |
| `eks-ec2-s3-dev` | AWS EKS + S3 + CloudFront (OAC) | Cloud (AWS) |
| `local-wsl-dev` | k3s on WSL2 | Local |

## Repository layout

```text
├── root.hcl                  Shared settings + generated provider.tf
├── envs/                     One Terragrunt unit per scenario
├── src/                      Self-contained Terraform roots
├── ansible/                  Playbooks and roles (nginx, deploy-site, eks)
├── kubernetes/base/          Manifests for the demo workload
├── scripts/                  deploy.sh, destroy.sh, WSL helpers
├── docs/                     Full documentation
└── .github/workflows/        validate.yml (CI) + deploy.yml (manual)
```

## Quick start

Requirements: Terraform >= 1.9, Terragrunt >= 0.68, Ansible, `aws` CLI for
cloud scenarios. `make install-tools` installs everything into your home
directory.

```bash
make validate                       # static checks only
./scripts/deploy.sh ec2-dev         # full local lifecycle
./scripts/destroy.sh ec2-dev
```

See [docs/usage.md](docs/usage.md) for the complete guide, including the
manual GitHub Actions deployment and required secrets.

## Cloud credentials

The manual **Deploy** workflow uses GitHub OIDC through the `AWS_ROLE_ARN`
secret. The EC2 Ansible step additionally needs `AWS_SSH_PRIVATE_KEY` and
`AWS_SSH_PUBLIC_KEY` secrets. Set `BUDGET_EMAIL` (locally or as a secret) to
enable the optional monthly AWS budget alert.

## Documentation

- [docs/README.md](docs/README.md) - overview
- [docs/architecture.md](docs/architecture.md) - layout and data flow
- [docs/usage.md](docs/usage.md) - local control and CI/CD
- [docs/development.md](docs/development.md) - validation and contribution

> This template creates real, billable resources in AWS. Use the manual
> `destroy` action or `./scripts/destroy.sh` after testing.
