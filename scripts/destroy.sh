#!/usr/bin/env bash
# Destroy one environment managed by Terragrunt.
# Usage: ./scripts/destroy.sh [scenario]
set -euo pipefail

cd "$(dirname "$0")/.."

SCENARIO="${1:-ec2-dev}"
ENV_DIR="envs/${SCENARIO}"

if [[ ! -f "${ENV_DIR}/terragrunt.hcl" ]]; then
  echo "Unknown scenario: ${SCENARIO}" >&2
  echo "Available: ec2-dev eks-fargate-dev eks-ec2-s3-dev local-wsl-dev" >&2
  exit 1
fi

command -v terragrunt >/dev/null || { echo "terragrunt is required" >&2; exit 1; }

read -r -p "AWS region [eu-central-1]: " aws_region
aws_region="${aws_region:-eu-central-1}"
export AWS_DEFAULT_REGION="$aws_region"

read -r -p "Destroy all Terraform-managed resources for '${SCENARIO}'? [yes/no]: " confirmation
[[ "$confirmation" == "yes" ]] || { echo "Cancelled."; exit 0; }

echo ">>> Destroying scenario '${SCENARIO}' ..."
terragrunt --working-dir "${ENV_DIR}" init
terragrunt --working-dir "${ENV_DIR}" destroy --auto-approve
