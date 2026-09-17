# AWS_Template Project Context

## Current verified status — 2026-09-17

Cost-safe hardening is implemented. Live deployment is NOT certified.
- Terraform 1.9.8, Terragrunt 0.68.2 validated locally.
- AWS provider: EC2 6.x; EKS 5.95–5.x (EKS module 20.x constraint).
- local-wsl has no AWS provider and defaults to a local backend outside the cache.
- All four Terraform roots and Terragrunt environments pass static validation.
- Local clean-cache init/validate/plan passes without AWS credentials.
- Ansible syntax/lint, yamllint, shellcheck, HCL/TF formatting, actionlint pass.
- Five offline unittest regression checks cover manifest paths/selectors, scenario
  rejection, no-systemd preflight, and workflow backend/cost guards.
- Actual local deployment stops before Terraform: host PID 1 is init(Ubuntu),
  not systemd. No sudo configuration or WSL restart was performed.
- No AWS apply/destroy was executed; no billable resources were created.
  Existing account resources and billing cannot be audited without credentials.

## Architecture and changes

Four self-contained roots under src/, one Terragrunt unit each under envs/.
Existing user changes (role naming/docs and Fargate namespace selector) retained.
- root.hcl generates a persistent local backend or optional pre-existing S3 backend.
- GitHub infrastructure-only Deploy requires backend variables, explicit cost
  acceptance for apply, and serializes operations per scenario/region.
- local-wsl removed from GitHub runner choices; it requires a user's WSL2 host.
- EC2 key/CIDR and tools are checked before apply; SSH wait added to Ansible.
- Scripts use working-directory subshells compatible with Terragrunt 0.68.2.
- EKS playbook paths fixed; deploy uses prebuilt application image, not ephemeral
  kubectl cp from a nonexistent checkout. Rollout and HTTP checks added.
- Fargate application selector preserved; kube-system DNS selector added.
- k3s installer uses INSTALL_K3S_VERSION and a dedicated kubeconfig, refusing
  incompatible existing installs instead of silently ignoring the version.
- Default scenario is local-wsl; make apply requires CONFIRM_COSTS=yes for AWS.

## Remaining live acceptance / limitations

1. Enable systemd in WSL2 and restart WSL from Windows; then local deploy,
   readiness/HTTP test, destroy; uninstall k3s only on a dedicated test host.
2. AWS tests intentionally deferred to avoid charges. Check region/version
   availability before EKS apply; old Kubernetes versions can incur extended
   support charges. EKS DNS scheduling (including CoreDNS compute-type annotation)
   and GHCR image accessibility still require live acceptance.
3. S3/CloudFront are infrastructure only: audio upload/app URL integration is not
   implemented. GitHub Deploy does not run Ansible or Kubernetes delivery.
4. Backend migration is mandatory for existing old-cache state; NEVER delete
   state or cache as a substitute for destroy. Preserve backend until cleanup is verified.
5. A zero AWS bill cannot be guaranteed by a budget alert or empty Terraform state.
   Audit ALL relevant regions, account billing and resources outside Terraform.

See README.md and docs/completion.md for the current cost-safe runbook.
The older validation claims below have been replaced by this verified status.
