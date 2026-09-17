## Current verified status — 2026-09-17

Cost-safe hardening is implemented. The cloud EC2 path is live-verified;
EKS scenarios are reference code and are explicitly NOT scheduled for live runs.
- Terraform 1.9.8, Terragrunt 0.68.2 validated locally.
- AWS provider: EC2 6.x; EKS 5.95–5.x (EKS module 20.x constraint).
- local-wsl has no AWS provider and defaults to a local backend outside the cache.
- All four Terraform roots and Terragrunt environments pass static validation.
- Local clean-cache init/validate/plan passes without AWS credentials.
- Ansible syntax/lint, yamllint, shellcheck, HCL/TF formatting, actionlint pass.
- Eleven offline unittest regression checks cover manifest paths/selectors,
  scenario rejection, no-systemd preflight, workflow backend/cost guards and
  the S3 audio delivery path with a recorded fake AWS CLI.
- Live EC2 E2E completed 2026-09-17 on the real account: Spot t3.micro created
  from the reviewed plan, AI_Nginx deployed by Ansible, HTTP smoke returned the
  Kyiv Skyline page, destroy succeeded (4/4 resources), empty state confirmed
  and AWS API re-check found no leftovers. The one-time cost appears in Billing
  with a delay and was explicitly accepted by the owner.
- EKS live runs are NOT planned (cost decision by the owner); the code and
  scenarios stay in the repository as reference. Do not schedule EKS applies.
- Local-wsl live E2E still blocked on this host only by WSL systemd being
  disabled (PID 1 is init(Ubuntu)); the owner can run it per docs/e2e.md.

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

1. Live E2E of `local-wsl`: enable systemd in WSL2 and restart WSL from Windows,
   then follow docs/e2e.md (deploy, readiness/HTTP checks, destroy). Uninstall
   k3s only on a dedicated test host.
2. EKS live runs are explicitly NOT planned (owner cost decision). The EKS and
   eks-ec2-s3 scenarios remain in the repo as reference code only. If they are
   ever revived, re-check region/version availability and extended-support
   charges first; do not schedule them silently.
3. The S3 audio delivery (sync-audio-to-s3.sh, eks_s3 role, /audio/* -> CloudFront
   redirect) is offline-tested only; live confirmation would belong to the EKS
   path, which is not scheduled.
4. Backend migration is mandatory for existing old-cache state; NEVER delete
   state or cache as a substitute for destroy. Preserve backend until cleanup is verified.
5. A zero AWS bill cannot be guaranteed by a budget alert or empty Terraform state.
   Audit ALL relevant regions, account billing and resources outside Terraform.

See README.md and docs/completion.md for the current cost-safe runbook.
The older validation claims below have been replaced by this verified status.
