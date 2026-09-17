#!/usr/bin/env bash
# Deploy one environment with Terragrunt (+ Ansible for the EC2 scenario).
# Usage: ./scripts/deploy.sh [scenario]
#
# Scenarios:
#   ec2          AWS EC2 + nginx (needs AWS credentials and an SSH key)
#   eks-fargate  AWS EKS on Fargate (needs AWS credentials)
#   eks-ec2-s3   AWS EKS + S3 + CloudFront (needs AWS credentials)
#   local-wsl    Local k3s on WSL2 (no cloud credentials required)
set -euo pipefail
export PATH="$PATH:/usr/local/bin"

cd "$(dirname "$0")/.."

SCENARIO="${1:-local-wsl}"
case "$SCENARIO" in
  ec2|eks-fargate|eks-ec2-s3|local-wsl) ;;
  *) echo 'Usage: deploy.sh {ec2|eks-fargate|eks-ec2-s3|local-wsl}' >&2; exit 1 ;;
esac
ENV_DIR="envs/${SCENARIO}"

if [[ ! -f "${ENV_DIR}/terragrunt.hcl" ]]; then
  echo "Unknown scenario: ${SCENARIO}" >&2
  echo "Available: ec2 eks-fargate eks-ec2-s3 local-wsl" >&2
  exit 1
fi

command -v terragrunt >/dev/null || { echo "terragrunt is required" >&2; exit 1; }
command -v curl >/dev/null || { echo "curl is required" >&2; exit 1; }

tg() { (cd "$ENV_DIR" && terragrunt "$@"); }

# Fail before provisioning, not after billable resources have been created.
if [[ "$SCENARIO" != local-wsl ]]; then
  for tool in aws ansible-playbook; do
    command -v "$tool" >/dev/null || { echo "$tool is required" >&2; exit 1; }
  done
  if [[ "$SCENARIO" == eks-* ]]; then
    if [[ "$SCENARIO" == eks-ec2-s3 ]]; then
      command -v git >/dev/null || { echo 'git is required for audio upload' >&2; exit 1; }
    fi
    command -v kubectl >/dev/null || { echo 'kubectl is required' >&2; exit 1; }
  fi
else
  command -v git >/dev/null || { echo 'git is required' >&2; exit 1; }
  [[ "$(ps -p 1 -o comm=)" == systemd ]] || { echo 'Enable systemd in WSL2 first' >&2; exit 1; }
  sudo -v
  export KUBECONFIG="$HOME/.kube/aws-template-k3s.yaml"
fi

# Cloud scenarios require AWS region, budget email and confirmation
if [[ "$SCENARIO" != "local-wsl" ]]; then
  read -r -p "AWS region [eu-central-1]: " aws_region
  aws_region="${aws_region:-eu-central-1}"
  export AWS_DEFAULT_REGION="$aws_region"

  read -r -p "Budget alert email (optional; leave blank to disable): " budget_email
  export BUDGET_EMAIL="$budget_email"

  read -r -p "This will create billable resources. Continue? [yes/no]: " confirmation
  [[ "$confirmation" == "yes" ]] || { echo "Cancelled."; exit 0; }
else
  aws_region="eu-central-1"
  export AWS_DEFAULT_REGION="$aws_region"
  budget_email=""
  export BUDGET_EMAIL="$budget_email"
fi

if [[ "$SCENARIO" == ec2 ]]; then
  read -r -p "SSH public key path [$HOME/.ssh/id_rsa.pub]: " public_key_path
  public_key_path="${public_key_path:-$HOME/.ssh/id_rsa.pub}"
  [[ -f "$public_key_path" && -f "${public_key_path%.pub}" ]] || { echo 'SSH key pair not found' >&2; exit 1; }
  public_key_path="$(realpath "$public_key_path")"
  runner_ip="$(curl -fsS --max-time 15 https://api.ipify.org)"
  export TF_VAR_public_key_path="$public_key_path"
  export TF_VAR_ssh_cidr_blocks="[\"${runner_ip}/32\"]"
fi
if [[ "$SCENARIO" != local-wsl ]]; then
  aws sts get-caller-identity >/dev/null
fi
trap 'echo "Deployment failed. Resources may remain; run scripts/destroy.sh for this scenario using the same state and region." >&2' ERR

echo ">>> Applying scenario '${SCENARIO}' ..."
tg init -input=false
tg plan -input=false
tg apply -input=false -auto-approve

case "$SCENARIO" in
  ec2)

  public_ip="$(tg output -raw public_ip)"
  umask 077
  cat > /tmp/aws-template-inventory.ini <<INV
[webservers]
${public_ip} ansible_user=ubuntu ansible_ssh_private_key_file='${public_key_path%.pub}' ansible_ssh_common_args='-o StrictHostKeyChecking=accept-new'
INV
  ANSIBLE_ROLES_PATH="ansible/roles" ansible-playbook -i /tmp/aws-template-inventory.ini ansible/playbooks/ec2.yml
  nginx_url="http://${public_ip}"
  echo ">>> AI_Nginx demo is live at: $nginx_url"
  curl -fsSL "$nginx_url" >/dev/null && echo ">>> Smoke test OK"
  ;;

  eks-fargate|eks-ec2-s3)
  cluster_name="$(tg output -raw cluster_name)"
  aws eks update-kubeconfig --name "$cluster_name" --region "$aws_region"
  if [[ "$SCENARIO" == eks-ec2-s3 ]]; then
    export AUDIO_BUCKET_NAME CLOUDFRONT_DOMAIN
    AUDIO_BUCKET_NAME="$(tg output -raw audio_bucket_name)"
    CLOUDFRONT_DOMAIN="$(tg output -raw cloudfront_domain)"
    ANSIBLE_ROLES_PATH="ansible/roles" ansible-playbook ansible/playbooks/eks-s3-deploy.yml
  else
    ANSIBLE_ROLES_PATH="ansible/roles" ansible-playbook ansible/playbooks/eks-deploy.yml
  fi
  echo ">>> Deployed. Use kubectl port-forward -n ai-nginx-demo svc/ai-nginx-app 8080:80 for local access."
  ;;

  local-wsl)
  command -v kubectl >/dev/null || { echo "kubectl is required for the local scenario" >&2; exit 1; }
  echo ">>> Cloning the AI_Nginx application repository ..."
  if [[ -d /opt/ai-nginx/.git ]]; then
    sudo git -C /opt/ai-nginx pull --ff-only
  else
    sudo mkdir -p /opt/ai-nginx
    sudo git clone --depth 1 https://github.com/Izanar/AI_Nginx.git /opt/ai-nginx
  fi
  echo ">>> Applying local Kubernetes manifests (AI_Nginx via nginx + hostPath) ..."
  kubectl apply -f kubernetes/local/namespace.yaml
  kubectl apply -f kubernetes/local/deployment.yaml
  kubectl apply -f kubernetes/local/service.yaml
  kubectl rollout status deployment/ai-nginx-app -n ai-nginx-demo --timeout=180s
  node_port="$(tg output -raw node_port)"
  echo ">>> AI_Nginx demo is live at: http://localhost:${node_port}"
  curl -fsSL "http://localhost:${node_port}" >/dev/null && echo ">>> Smoke test OK"
  ;;

  *)
  echo "Unknown scenario: $SCENARIO" >&2
  exit 1
  ;;
esac
