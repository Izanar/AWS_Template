#!/usr/bin/env bash
# Install k3s (Kubernetes on lightweight containers) for WSL2.
# Usage: install-wsl-kubernetes.sh [k3s-version]
set -euo pipefail

K3S_VERSION="${1:-v1.31.1+k3s1}"

if command -v k3s >/dev/null 2>&1; then
  INSTALLED_VERSION="$(k3s version --short 2>/dev/null || true)"
  echo "k3s is already installed: ${INSTALLED_VERSION}"
  echo "Requested version: ${K3S_VERSION}"
  echo "Re-run with a different version to upgrade, or uninstall the current one first."
  exit 0
fi

echo "Installing k3s ${K3S_VERSION} ..."
curl -fsSL https://get.k3s.io | K3S_VERSION="${K3S_VERSION}" sh

echo "k3s installed. Run 'k3s kubectl get-nodes' to verify the cluster."
echo "Note: on WSL2 the k3s server needs to be run inside a systemd session (systemctl start k3s)."
