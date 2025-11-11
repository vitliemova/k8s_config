#!/bin/bash
SCRIPT_PATH="$(readlink -nf $0)"
export SCRIPT_DIR="$(dirname $SCRIPT_PATH)"
SCRIPT_FULLNAME="$(basename $SCRIPT_PATH)"
SCRIPT_NAME="${SCRIPT_FULLNAME%%.*}"
#--- log files
export SCRIPT_LOGDIR="${SCRIPT_DIR}"
export SCRIPT_LOGFILE="${SCRIPT_LOGDIR}/${SCRIPT_NAME}.log"

export HOME =/home/desi
# # Load environment variables from .env | tee -a "${SCRIPT_LOGFILE}"
# if [ -f "/home/desi/.env" ]; then
#   echo "[INFO] Loading environment variables from .env" | tee -a "${SCRIPT_LOGFILE}"  
#   set -a
#   source /home/desi/.env
#   set +a
#   echo $K3S_URL | tee -a "${SCRIPT_LOGFILE}"  
#   echo $K3S_TOKEN | tee -a "${SCRIPT_LOGFILE}"
#   SERVER_IP=$(echo $K3S_URL | sed 's|https://||;s|:6443||')
#   #NODE_TOKEN=$K3S_TOKEN
# else
#   echo "[WARN] .env file not found, please export K3S_URL and K3S_TOKEN manually" | tee -a "${SCRIPT_LOGFILE}"
# fi
# SERVER_IP=$(ssh desi@my-control-plane "hostname -I | tr ' ' '\n' | grep '^192\.168\.' | head -n1")

NODE_TOKEN=$(ssh root@${SERVER_IP} "sudo cat /var/lib/rancher/k3s/server/node-token")

set -e

echo "Step1  Installing k3s agent..." | tee -a "${SCRIPT_LOGFILE}"

# Update system
apt-get update -y && sudo apt-get upgrade -y | tee -a "${SCRIPT_LOGFILE}"

# Disable swap | tee -a "${SCRIPT_LOGFILE}"
swapoff -a | tee -a "${SCRIPT_LOGFILE}"
sed -i '/ swap / s/^/#/' /etc/fstab | tee -a "${SCRIPT_LOGFILE}"

# Install prerequisites | tee -a "${SCRIPT_LOGFILE}"
apt-get install -y curl apt-transport-https ca-certificates gnupg lsb-release | tee -a "${SCRIPT_LOGFILE}"

# --- NEW: Install Docker ---
echo "[INFO] Installing Docker..." | tee -a "${SCRIPT_LOGFILE}"
apt-get install -y docker.io | tee -a "${SCRIPT_LOGFILE}"
systemctl enable --now docker | tee -a "${SCRIPT_LOGFILE}"
usermod -aG docker $USER | tee -a "${SCRIPT_LOGFILE}"
usermod -aG docker desi | tee -a "${SCRIPT_LOGFILE}"

# Install k3s agent (join cluster) | tee -a "${SCRIPT_LOGFILE}"
echo "[INFO] Joining the Kubernetes cluster as a worker node..." | tee -a "${SCRIPT_LOGFILE}"
curl -sfL https://get.k3s.io | K3S_URL=https://${SERVER_IP}:6443 K3S_TOKEN=${NODE_TOKEN} sh -

echo "[INFO] Worker node joined the cluster."

# --- NEW: Configure kubectl on this node ---
echo "[INFO] Setting up kubeconfig for kubectl..." | tee -a "${SCRIPT_LOGFILE}"
mkdir -p $HOME/.kube
# Copy kubeconfig from server via scp (requires SSH access)
scp root@${SERVER_IP}:/etc/rancher/k3s/k3s.yaml $HOME/.kube/config

# Fix ownership and permissions
chown $(id -u):$(id -g) $HOME/.kube/config
chmod 600 $HOME/.kube/config

echo "[INFO] kubeconfig configured. Testing cluster access..." | tee -a "${SCRIPT_LOGFILE}"
kubectl get nodes | tee -a "${SCRIPT_LOGFILE}"