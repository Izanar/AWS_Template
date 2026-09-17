#!/usr/bin/env bash
# Destroy one environment managed by Terragrunt.
# Usage: ./scripts/destroy.sh [scenario]
set -euo pipefail

cd "$(dirname "$0")/.."

SCENARIO="${1:-local-wsl}"
case "$SCENARIO" in
  ec2|eks-fargate|eks-ec2-s3|local-wsl) ;;
  *) echo 'Unknown scenario' >&2; exit 1 ;;
esac
ENV_DIR="envs/${SCENARIO}"

if [[ ! -f "${ENV_DIR}/terragrunt.hcl" ]]; then
  echo "Unknown scenario: ${SCENARIO}" >&2
  echo "Available: ec2 eks-fargate eks-ec2-s3 local-wsl" >&2
  exit 1
fi

command -v terragrunt >/dev/null || { echo "terragrunt is required" >&2; exit 1; }

if [[ "$SCENARIO" == local-wsl ]]; then
  export KUBECONFIG="$HOME/.kube/aws-template-k3s.yaml"
else
  read -r -p "AWS region [eu-central-1]: " aws_region
  export AWS_DEFAULT_REGION="${aws_region:-eu-central-1}"
fi

read -r -p "Destroy all Terraform-managed resources for '${SCENARIO}'? [yes/no]: " confirmation
[[ "$confirmation" == "yes" ]] || { echo "Cancelled."; exit 0; }

echo ">>> Destroying scenario '${SCENARIO}' ..."

if [[ "$SCENARIO" == "local-wsl" ]] && command -v kubectl >/dev/null; then
  echo ">>> Removing the AI_Nginx demo from local Kubernetes ..."
  kubectl delete -f kubernetes/local/service.yaml --ignore-not-found
  kubectl delete -f kubernetes/local/deployment.yaml --ignore-not-found
  kubectl delete -f kubernetes/local/namespace.yaml --ignore-not-found
  echo ">>> App checkout /opt/ai-nginx left in place (remove it manually if unwanted)."
fi

(cd "$ENV_DIR" && terragrunt init -input=false && terragrunt destroy -auto-approve)
echo 'Terraform destroy finished. Check billing and any resources managed outside this state.'
if [[ "$SCENARIO" == local-wsl ]]; then
  echo 'k3s remains installed. On a dedicated test host, sudo /usr/local/bin/k3s-uninstall.sh removes the entire cluster.'
fi
