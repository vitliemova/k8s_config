#!/bin/bash

#--- scriptname
SCRIPT_PATH="$(readlink -nf $0)"
export SCRIPT_DIR="$(dirname $SCRIPT_PATH)"
SCRIPT_FULLNAME="$(basename $SCRIPT_PATH)"
SCRIPT_NAME="${SCRIPT_FULLNAME%%.*}"
#--- log files
export SCRIPT_LOGDIR="${SCRIPT_DIR}"
export SCRIPT_LOGFILE="${SCRIPT_LOGDIR}/${SCRIPT_NAME}.log"

set -e

echo "Step 1 Starting Kubernetes (k3s) installation on Ubuntu..." | tee -a "${SCRIPT_LOGFILE}"

# Update system packages
sudo apt-get update -y | tee -a "${SCRIPT_LOGFILE}"
sudo apt-get upgrade -y | tee -a "${SCRIPT_LOGFILE}"

# Disable swap (required by Kubernetes) | tee -a "${SCRIPT_LOGFILE}"
echo "[INFO] Disabling swap..."
sudo swapoff -a | tee -a "${SCRIPT_LOGFILE}"
sudo sed -i '/ swap / s/^/#/' /etc/fstab | tee -a "${SCRIPT_LOGFILE}"

# Ensure required tools are installed
echo "[INFO] Installing prerequisites..." | tee -a "${SCRIPT_LOGFILE}"
sudo apt-get install -y curl apt-transport-https ca-certificates gnupg lsb-release | tee -a "${SCRIPT_LOGFILE}"

# Install k3s (lightweight Kubernetes) | tee -a "${SCRIPT_LOGFILE}"
echo "[INFO] Installing k3s..." | tee -a "${SCRIPT_LOGFILE}"
curl -sfL https://get.k3s.io | sh - | tee -a "${SCRIPT_LOGFILE}"

# Wait for k3s service to start | tee -a "${SCRIPT_LOGFILE}"
echo "[INFO] Waiting for k3s service to initialize..."
sleep 20 

# Step 2 Setup kubectl (k3s bundles kubectl already) | tee -a "${SCRIPT_LOGFILE}"
echo "[INFO] Configuring kubectl..." | tee -a "${SCRIPT_LOGFILE}"
mkdir -p $HOME/.kube | tee -a "${SCRIPT_LOGFILE}"
sudo cp /etc/rancher/k3s/k3s.yaml $HOME/.kube/config | tee -a "${SCRIPT_LOGFILE}"
sudo chown $(id -u):$(id -g) $HOME/.kube/config | tee -a "${SCRIPT_LOGFILE}"
sudo chmod 644 /etc/rancher/k3s/k3s.yaml | tee -a "${SCRIPT_LOGFILE}"

# Replace localhost with VM IP in kubeconfig | tee -a "${SCRIPT_LOGFILE}"
VM_IP=$(hostname -I | awk '{print $1}') | tee -a "${SCRIPT_LOGFILE}"
sed -i "s/127.0.0.1/$VM_IP/" $HOME/.kube/config | tee -a "${SCRIPT_LOGFILE}"
 
# Step 3 Verify installation | tee -a "${SCRIPT_LOGFILE}"
echo "[INFO] Kubernetes cluster status:" | tee -a "${SCRIPT_LOGFILE}"
kubectl get nodes | tee -a "${SCRIPT_LOGFILE}"

# Step 4 echo "[INFO] Server node installed. Use the token below to join agents:" | tee -a "${SCRIPT_LOGFILE}"
sudo cat /var/lib/rancher/k3s/server/node-token | tee -a "${SCRIPT_LOGFILE}"