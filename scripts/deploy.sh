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

read -r -p "AWS region [eu-central-1]: " aws_region
aws_region="${aws_region:-eu-central-1}"
export AWS_DEFAULT_REGION="$aws_region"

read -r -p "Budget alert email (optional; leave blank to disable): " budget_email
export BUDGET_EMAIL="$budget_email"

read -r -p "This will create billable resources. Continue? [yes/no]: " confirmation
[[ "$confirmation" == "yes" ]] || { echo "Cancelled."; exit 0; }

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
    cat > /tmp/image-test-env-inventory.ini <<EOF
[webservers]
web1 ansible_host=${public_ip} ansible_user=ubuntu ansible_ssh_private_key_file=${public_key_path%.*} ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
EOF
    ansible-playbook -i /tmp/image-test-env-inventory.ini ansible/playbooks/ec2.yml
    curl -fsS --max-time 60 "http://${public_ip}" -o /dev/null
    printf 'Application URL: http://%s\n' "$public_ip"
    ;;
  *)
    echo ">>> Deployment finished. Inspect outputs with:"
    echo "    terragrunt --working-dir ${ENV_DIR} output"
    ;;
esac
