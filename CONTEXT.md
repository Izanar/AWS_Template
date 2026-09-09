# ImageTestEnv Project Context

## Summary

The repository was transformed into a reusable Terraform/Ansible/Kubernetes
template with Terragrunt. The previous intermediate layout (`modules/`,
`terraform/`, `terragrunt/`) was replaced by four self-contained environment
roots under `src/`, wired to the Terragrunt units under `envs/`.

## What Has Been Done

### Self-contained Terraform roots (`src/`)
- `src/ec2` (main.tf, variables.tf, outputs.tf) - EC2 + budget
- `src/eks-fargate` (main.tf, variables.tf, outputs.tf) - VPC + EKS + budget
- `src/eks-ec2-s3` (main.tf, variables.tf, outputs.tf) - VPC + EKS + S3 + CloudFront + budget
- `src/local-wsl` (main.tf, variables.tf, outputs.tf) - k3s via local-exec

Each root is cache-safe: no relative sibling paths, only registry modules from
`terraform-aws-modules`.

### Terragrunt Configuration
- Root `root.hcl` with provider generation (aws ~> 6.0, Terraform >= 1.9)
  and common locals
- Environment configurations with `terraform.source` pointing to `src/*`:
  - `envs/ec2/terragrunt.hcl`
  - `envs/eks-fargate/terragrunt.hcl`
  - `envs/eks-ec2-s3/terragrunt.hcl`
  - `envs/local-wsl/terragrunt.hcl`

### Ansible Roles and Playbooks
- Roles: `nginx`, `deploy-site`, `eks`
- Playbooks: `ansible/playbooks/ec2.yml`, `ansible/playbooks/eks-deploy.yml`

### Kubernetes Manifests
- Base manifests in `kubernetes/base/`: `namespace.yaml`, `deployment.yaml`, `service.yaml`

### GitHub Actions
- `validate.yml` - CI on push/PR (terraform fmt/validate, ansible, yamllint, shellcheck)
- `deploy.yml` - manual apply/destroy per scenario with AWS OIDC
- `build-images.yml` - manual image builds for the feature branches

### Scripts
- `scripts/deploy.sh`, `scripts/destroy.sh` - scenario-aware lifecycle control
- `scripts/install-wsl-kubernetes.sh`, `scripts/configure-wsl-network.sh` - WSL helpers

### Tooling
- Makefile with validate/fmt/init/plan/apply/destroy/output/lint/test targets
- pre-commit configuration (terraform, ansible-lint, yamllint, shellcheck)
- Documentation in `docs/`

## Validation status

- Terraform: `terraform init` + `validate` pass for all `src/*` roots (TF 1.16.2,
  aws provider 6.x)
- Terragrunt: `render` + `init` pass for all four envs; `plan` pass for
  `local-wsl` (no cloud credentials needed)
- Ansible: playbook syntax checks pass
- Kubernetes: manifests parse cleanly under yamllint

## What Remains to Be Done

- [ ] Run `terragrunt apply` against a real AWS account for `ec2`,
      `eks-fargate` and `eks-ec2-s3` (requires AWS credentials/OIDC role)
- [ ] Deploy the demo workload to a real cluster (EKS or local k3s) and observe
      the readiness probes
- [ ] If the previous `modules/` layout is still referenced anywhere (docs,
      branches), update or remove those references
- [ ] Consider adding automated infrastructure tests (Terratest / InSpec /
      k8s conformance) once the apply path is verified

## Next Steps for Continuation

1. Export AWS credentials or configure `AWS_ROLE_ARN` OIDC in GitHub.
2. Run `make validate` to confirm the tree is healthy.
3. Run `./scripts/deploy.sh ec2` (or the manual `deploy.yml` action) and
   verify the nginx page and the budget alert.
4. Repeat for the EKS scenarios, then `./scripts/destroy.sh <scenario>`.
5. Test `local-wsl` on an actual WSL2 host (k3s + port forwarding).
