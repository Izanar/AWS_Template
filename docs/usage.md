# Usage

## Quick start

```bash
# 1. Install Terraform, Terragrunt and Python tooling (into ~/.local/bin)
make install-tools

# 2. Pick a scenario and deploy it (interactive; asks for region/email)
./scripts/deploy.sh ec2

# 3. When you are done, destroy the same resources
./scripts/destroy.sh ec2
```

## Scenario run guides

Every scenario deploys the same [AI_Nginx](https://github.com/Izanar/AI_Nginx)
application: nginx is installed and started, the AI_Nginx content is served,
and a smoke test verifies the page responds. Each scenario is a Terragrunt
environment under `envs/`. Deploy creates real, billable resources (except
`local-wsl`, which is local only).

### 1. `ec2` — AWS EC2 + nginx (Ansible)

**Requirements:** AWS credentials, `aws` CLI, `ansible-playbook`, an SSH key
pair (`~/.ssh/id_rsa.pub` by default).

```bash
# Make sure your keys are present before you start
ls -l ~/.ssh/id_rsa ~/.ssh/id_rsa.pub
aws sts get-caller-identity          # verify AWS credentials

./scripts/deploy.sh ec2          # creates EC2, prints the nginx URL
#    -> asks region, budget email, SSH key path and your public IP (optional)
#    -> the runner's IP is added to the SSH security group automatically

# Re-run the nginx provisioning at any time against the same instance
ansible-playbook -i /tmp/aws-template-inventory.ini ansible/nginx.yml

# Inspect the deployed demo
curl "$(./scripts/deploy.sh ec2 --help >/dev/null; terragrunt --working-dir envs/ec2 output -raw nginx_url)"

./scripts/destroy.sh ec2         # destroys the instance and all wiring
```

**Outputs:** `public_ip`, `nginx_url`, `instance_id`.

### 2. `eks-fargate` — AWS EKS on Fargate

**Requirements:** AWS credentials, `aws` CLI, `kubectl`.

```bash
aws sts get-caller-identity

./scripts/deploy.sh eks-fargate  # creates the EKS control plane + profiles
#    -> takes 15-25 minutes; the kubeconfig snippet is printed at the end

# Connect kubectl to the new cluster (replace the printed values)
aws eks update-kubeconfig --name "$(terragrunt --working-dir envs/eks-fargate output -raw cluster_name)" --region eu-central-1
kubectl get nodes
kubectl apply -k k8s/                 # deploy the demo workload

./scripts/destroy.sh eks-fargate # destroys the cluster (also 15-25 min)
```

**Outputs:** `cluster_name`, `cluster_endpoint`.

### 3. `eks-ec2-s3` — AWS EKS + S3 + CloudFront (OAC)

**Requirements:** AWS credentials, `aws` CLI, `kubectl`.

```bash
aws sts get-caller-identity

./scripts/deploy.sh eks-ec2-s3   # EKS + S3 bucket + CloudFront with OAC
#    -> same 15-25 minutes; S3 and CloudFront serve the static demo

aws eks update-kubeconfig --name "$(terragrunt --working-dir envs/eks-ec2-s3 output -raw cluster_name)" --region eu-central-1
kubectl get nodes

# Check the CDN-served demo
curl "$(terragrunt --working-dir envs/eks-ec2-s3 output -raw demo_url)"

./scripts/destroy.sh eks-ec2-s3  # destroys the cluster, bucket and CDN
```

**Outputs:** `cluster_name`, `bucket_name`, `demo_url`.

### 4. `local-wsl` — k3s on WSL2 (no cloud)

**Requirements:** WSL2 with `kubectl`. The install script sets up k3s for you.

```bash
# One-time preparation of WSL2 networking and k3s
./scripts/install-wsl-kubernetes.sh
./scripts/configure-wsl-network.sh   # fixes DNS/firewall inside WSL2

./scripts/deploy.sh local-wsl    # brings up the local k3s demo
kubectl get nodes                    # single k3s node
kubectl get pods -A

./scripts/destroy.sh local-wsl   # removes the local demo resources
```

Nothing billable here; it runs entirely on your machine.

## Environment variables

Set them in the shell or let `deploy.sh` prompt you:

```bash
export AWS_DEFAULT_REGION=eu-central-1
export BUDGET_EMAIL=you@example.com   # optional
```

`BUDGET_EMAIL` enables an AWS Budget (COST, monthly) alert at 80% of
`monthly_budget_usd` (default 5 USD). AWS Billing permissions are required.

## Individual Terragrunt commands

```bash
make init   ENV=ec2        # terragrunt init
make plan   ENV=ec2        # terragrunt plan
make apply  ENV=ec2        # terragrunt apply (creates resources)
make output ENV=ec2        # print terraform outputs
make destroy ENV=ec2       # terragrunt destroy
```

Supported `ENV` values: `ec2`, `eks-fargate`, `eks-ec2-s3`,
`local-wsl`.

`make validate` checks Terraform, Ansible, Kubernetes YAML and Shell scripts.

> The `ec2` scenario needs an SSH key pair. `public_key_path` defaults to
> `~/.ssh/id_rsa.pub`; the corresponding private key is used by Ansible.

## GitHub Actions

The repository ships two workflows:

- `validate.yml` - runs on every push/PR: `terraform fmt` + `validate`,
  Ansible syntax check, yamllint, shellcheck.
- `deploy.yml` (manual) - choose a scenario and `apply` or `destroy`. Cloud
  scenarios assume an OIDC role announced by the `AWS_ROLE_ARN` secret.

### Required secrets (cloud scenarios)

- `AWS_ROLE_ARN` - role that trusts GitHub OIDC for this repository.
- `AWS_SSH_PRIVATE_KEY` / `AWS_SSH_PUBLIC_KEY` - SSH keys used by the `ec2`
  Ansible provisioning.
