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

cd "$(dirname "$0")/.."

SCENARIO="${1:-ec2}"
ENV_DIR="envs/${SCENARIO}"

if [[ ! -f "${ENV_DIR}/terragrunt.hcl" ]]; then
  echo "Unknown scenario: ${SCENARIO}" >&2
  echo "Available: ec2 eks-fargate eks-ec2-s3 local-wsl" >&2
  exit 1
fi

command -v terragrunt >/dev/null || { echo "terragrunt is required" >&2; exit 1; }
command -v curl >/dev/null || { echo "curl is required" >&2; exit 1; }

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

echo ">>> Applying scenario '${SCENARIO}' ..."
terragrunt --working-dir "${ENV_DIR}" init
terragrunt --working-dir "${ENV_DIR}" plan -input=false
terragrunt --working-dir "${ENV_DIR}" apply -auto-approve

case "$SCENARIO" in
  ec2)
  command -v aws >/dev/null || { echo "aws CLI is required for the EC2 scenario" >&2; exit 1; }
  command -v ansible-playbook >/dev/null || { echo "ansible-playbook is required for the EC2 scenario" >&2; exit 1; }

  read -r -p "SSH public key path [$HOME/.ssh/id_rsa.pub]: " public_key_path
  public_key_path="${public_key_path:-$HOME/.ssh/id_rsa.pub}"
  read -r -p "Your public IPv4/CIDR for SSH (optional; not the instance IP): " user_public_ip

  runner_ip="$(curl -fsSL https://api.ipify.org)"
  ssh_cidrs="[\"${runner_ip}/32\""
  if [[ -n "$user_public_ip" ]]; then
    [[ "$user_public_ip" == */* ]] || user_public_ip+="/32"
    ssh_cidrs+=" ,\"${user_public_ip}\""
  fi
  ssh_cidrs+="]"

  public_ip="$(terragrunt --working-dir "${ENV_DIR}" output -raw public_ip)"
  cat > /tmp/aws-template-inventory.ini <<INV
[webservers]
${public_ip} ansible_user=ubuntu ansible_ssh_private_key_file=${public_key_path%.pub}
[webservers:vars]
nginx_ssh_cidrs=${ssh_cidrs}
INV
  ANSIBLE_ROLES_PATH="ansible/roles" ansible-playbook -i /tmp/aws-template-inventory.ini ansible/playbooks/ec2.yml
  nginx_url="http://${public_ip}"
  echo ">>> AI_Nginx demo is live at: $nginx_url"
  curl -fsSL "$nginx_url" >/dev/null && echo ">>> Smoke test OK"
  ;;

  eks-fargate)
  command -v kubectl >/dev/null || { echo "kubectl is required for the EKS scenarios" >&2; exit 1; }
  cluster_name="$(terragrunt --working-dir "${ENV_DIR}" output -raw cluster_name)"
  aws eks update-kubeconfig --name "$cluster_name" --region "$aws_region"
  echo ">>> Applying the EKS deployment playbook (AI_Nginx image) ..."
  ANSIBLE_ROLES_PATH="ansible/roles" ansible-playbook ansible/playbooks/eks-deploy.yml
  echo ">>> Deployed. kubectl get pods -n ai-nginx-demo to watch it come up."
  ;;

  eks-ec2-s3)
  command -v kubectl >/dev/null || { echo "kubectl is required for the EKS scenarios" >&2; exit 1; }
  cluster_name="$(terragrunt --working-dir "${ENV_DIR}" output -raw cluster_name)"
  aws eks update-kubeconfig --name "$cluster_name" --region "$aws_region"
  echo ">>> Applying the EKS deployment playbook (AI_Nginx image) ..."
  ANSIBLE_ROLES_PATH="ansible/roles" ansible-playbook ansible/playbooks/eks-deploy.yml
  echo ">>> Deployed. kubectl get pods -n ai-nginx-demo to watch it come up."
  ;;

  local-wsl)
  command -v kubectl >/dev/null || { echo "kubectl is required for the local scenario" >&2; exit 1; }
  echo ">>> Cloning the AI_Nginx application repository ..."
  if [[ -d /opt/ai-nginx/.git ]]; then
    git -C /opt/ai-nginx pull --ff-only
  else
    sudo mkdir -p /opt/ai-nginx
    sudo git clone --depth 1 https://github.com/Izanar/AI_Nginx.git /opt/ai-nginx
  fi
  echo ">>> Applying local Kubernetes manifests (AI_Nginx via nginx + hostPath) ..."
  kubectl apply -f kubernetes/local/namespace.yaml
  kubectl apply -f kubernetes/local/deployment.yaml
  kubectl apply -f kubernetes/local/service.yaml
  kubectl rollout status deployment/ai-nginx-app -n ai-nginx-demo --timeout=180s
  node_port="$(terragrunt --working-dir "${ENV_DIR}" output -raw node_port 2>/dev/null || echo 30080)"
  echo ">>> AI_Nginx demo is live at: http://localhost:${node_port}"
  curl -fsSL "http://localhost:${node_port}" >/dev/null && echo ">>> Smoke test OK"
  ;;

  *)
  echo "Unknown scenario: $SCENARIO" >&2
  exit 1
  ;;
esac
