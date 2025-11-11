#!/bin/bash
set -e

echo "[INFO] Installing k3s agent..."

# Update system
sudo apt-get update -y && sudo apt-get upgrade -y

# Disable swap
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab

# Install prerequisites
sudo apt-get install -y curl apt-transport-https ca-certificates gnupg lsb-release

# Install k3s agent (join cluster)
curl -sfL https://get.k3s.io | K3S_URL=https://<SERVER_IP>:6443 K3S_TOKEN=<NODE_TOKEN> sh -

echo "[INFO] Worker node joined the cluster."
