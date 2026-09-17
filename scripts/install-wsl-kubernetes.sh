#!/usr/bin/env bash
# Install k3s on a systemd-enabled WSL2 host; never overwrite the user's kubeconfig.
set -euo pipefail
K3S_VERSION="${1:-v1.31.1+k3s1}"
[[ "$(ps -p 1 -o comm=)" == systemd ]] || { echo 'Enable systemd in WSL2 first' >&2; exit 1; }
sudo -v
if command -v k3s >/dev/null 2>&1; then
  installed="$(k3s --version | head -1)"
  [[ "$installed" == *" ${K3S_VERSION} "* ]] || {
    echo "Existing k3s version differs: $installed. Upgrade explicitly before deploying." >&2
    exit 1
  }
else
  installer="$(mktemp)"
  trap 'rm -f "$installer"' EXIT
  curl -fsSL https://get.k3s.io -o "$installer"
  sudo env INSTALL_K3S_VERSION="$K3S_VERSION" sh "$installer"
fi
sudo systemctl start k3s
mkdir -p "$HOME/.kube"
sudo install -m 600 -o "$(id -u)" -g "$(id -g)" /etc/rancher/k3s/k3s.yaml "$HOME/.kube/aws-template-k3s.yaml"
export KUBECONFIG="$HOME/.kube/aws-template-k3s.yaml"
kubectl wait --for=condition=Ready node --all --timeout=180s
printf 'Use: export KUBECONFIG=%s/.kube/aws-template-k3s.yaml\n' "$HOME"
