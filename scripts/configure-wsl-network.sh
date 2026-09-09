#!/usr/bin/env bash
# Print firewall/network instructions for reaching an application deployed on a
# local WSL k3s cluster from the Windows host.
# Usage: configure-wsl-network.sh [node-port]
set -euo pipefail

NODE_PORT="${1:-30080}"

echo "=============================================="
echo " WSL k3s network configuration"
echo "=============================================="
echo
echo "1. The k3s cluster listens on the WSL2 virtual interface."
echo "   Find the WSL2 IP from WSL:"
echo "     ip -4 addr show eth0 | grep inet"
echo
echo "2. From Windows, forward the local port to the WSL2 IP"
echo "   (run in PowerShell):"
echo
echo "   netsh interface portproxy add v4tov4 listenport=${NODE_PORT} listenaddress=0.0.0.0 connectport=${NODE_PORT} connectaddress=<WSL2_IP>"
echo
echo "3. Allow inbound traffic on the Windows firewall:"
echo
echo "   netsh advfirewall firewall add rule name='k3s-${NODE_PORT}' dir=in action=allow protocol=TCP localport=${NODE_PORT}"
echo
echo "4. Verify from the Windows host:"
echo
echo "   curl http://localhost:${NODE_PORT}"
echo
echo "=============================================="
