# Development

## Validation

Run the full static validation suite:

```bash
make validate
```

It covers:

| Target | Tool | What it checks |
|---|---|---|
| `validate-tf` | `terraform fmt -check` + `terraform init`/`validate` per `src/*` | Terraform syntax and provider resolution |
| `validate-ansible` | `ansible-playbook --syntax-check`, `ansible-lint` | Playbook/role correctness |
| `validate-k8s` | PyYAML + `yamllint` | Manifest parsing and YAML style |
| `validate-shell` | `shellcheck` | Bash scripts under `scripts/` |

Pre-commit hooks run the same checks on every commit:

```bash
make precommit    # pre-commit run --all-files
```

Configure them once with `pre-commit install`.

## Constraints

- Terraform `>= 1.9.0` because the sources use `data` blocks and the AWS
  provider `~> 6.0` is required for `aws_budgets_budget`.
- Terragrunt `>= 0.68.0` because the env units use `terraform.source` with
  `inputs`.
- Never reference sibling directories from a `src/` root: Terragrunt copies
  source trees into a cache, so relative siblings do not exist at run time.
  Use registry modules (`terraform-aws-modules/*`) or inline resources instead.

## Applying a new scenario

1. Create `src/<new>/` with `main.tf`/`variables.tf`/`outputs.tf`.
2. Create `envs/<new>/terragrunt.hcl` mirroring an existing unit.
3. Validate with `make validate` and run `make plan ENV=<new>`.

## AWS notes

- Cloud scenarios create billable resources (`t3.micro`/`t3.small` nodes, VPCs,
  EKS clusters, S3 buckets, CloudFront distributions). Always `destroy` after
  testing or rely on the manual `destroy` action.
- The EC2 instance uses Spot capacity and may be reclaimed by AWS at any time;
  a failed workflow can leave resources behind, so the manual destroy action
  exists.

## Feature branches

The Kubernetes docker image scenarios originally lived in
`feature/eks-fargate-ha`, `feature/eks-ec2-s3` and
`feature/local-kubernetes-wsl`. `main` is the consolidated template; the image
build workflow (`build-images.yml`) can still publish containers from those
branches to GHCR.
