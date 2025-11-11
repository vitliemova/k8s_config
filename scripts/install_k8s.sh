#!/bin/bash

#--- scriptname
SCRIPT_PATH="$(readlink -nf $0)"
export SCRIPT_DIR="$(dirname $SCRIPT_PATH)"
SCRIPT_FULLNAME="$(basename $SCRIPT_PATH)"
SCRIPT_NAME="${SCRIPT_FULLNAME%%.*}"
#--- log files
export SCRIPT_LOGDIR="${SCRIPT_DIR}"
export SCRIPT_LOGFILE="${SCRIPT_LOGDIR}/${SCRIPT_NAME}.log"

export HOME=/home/desi

set -e

echo "Step 1 Starting Kubernetes (k3s) installation on Ubuntu..." | tee -a "${SCRIPT_LOGFILE}"

echo "a. Update system packages" | tee -a "${SCRIPT_LOGFILE}"
apt-get update -y | tee -a "${SCRIPT_LOGFILE}"
apt-get upgrade -y | tee -a "${SCRIPT_LOGFILE}"

echo "b. Disable swap (required by Kubernetes)" | tee -a "${SCRIPT_LOGFILE}"
swapoff -a | tee -a "${SCRIPT_LOGFILE}"
sed -i '/ swap / s/^/#/' /etc/fstab | tee -a "${SCRIPT_LOGFILE}"


echo "c. Install Docker (optional, for building images locally) "| tee -a "${SCRIPT_LOGFILE}"
apt-get install -y docker.io | tee -a "${SCRIPT_LOGFILE}"
systemctl enable --now docker | tee -a "${SCRIPT_LOGFILE}"
usermod -aG docker $USER | tee -a "${SCRIPT_LOGFILE}"
usermod -aG docker desi | tee -a "${SCRIPT_LOGFILE}"

echo "d . Installing prerequisites..." | tee -a "${SCRIPT_LOGFILE}"
apt-get install -y curl apt-transport-https ca-certificates gnupg lsb-release | tee -a "${SCRIPT_LOGFILE}"

echo "e. [INFO] Installing k3s..." | tee -a "${SCRIPT_LOGFILE}"
curl -sfL https://get.k3s.io | sh - | tee -a "${SCRIPT_LOGFILE}"

echo "[INFO] Waiting for k3s service to initialize..." | tee -a "${SCRIPT_LOGFILE}"
sleep 20

echo "# Step 2 Setup kubectl (k3s bundles kubectl already)" | tee -a "${SCRIPT_LOGFILE}"
mkdir -p $HOME/.kube | tee -a "${SCRIPT_LOGFILE}"
cp /etc/rancher/k3s/k3s.yaml $HOME/.kube/config | tee -a "${SCRIPT_LOGFILE}"
chown $(id -u):$(id -g) $HOME/.kube/config | tee -a "${SCRIPT_LOGFILE}"
chmod 644 /etc/rancher/k3s/k3s.yaml | tee -a "${SCRIPT_LOGFILE}"

# Replace localhost with VM IP in kubeconfig | tee -a "${SCRIPT_LOGFILE}"
VM_IP=$(hostname -I | awk '{print $1}')
echo "2. a : VM IP: $VM_IP" | tee -a "${SCRIPT_LOGFILE}"
sed -i "s/127.0.0.1/$VM_IP/" $HOME/.kube/config
sed -i "s/127.0.0.1/$VM_IP/" /etc/rancher/k3s/k3s.yaml

# Step 3 Verify installation
echo " Step 3 Kubernetes cluster status:" | tee -a "${SCRIPT_LOGFILE}"
kubectl get nodes | tee -a "${SCRIPT_LOGFILE}"

echo "Step 4  Server node installed. Use the token below to join agents:" | tee -a "${SCRIPT_LOGFILE}"
cat /var/lib/rancher/k3s/server/node-token | tee -a "${SCRIPT_LOGFILE}"

# # Step 5 Install Helm
# echo "Step 5 Installing Helm..." | tee -a "${SCRIPT_LOGFILE}"
# curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash | tee -a "${SCRIPT_LOGFILE}"

# # Step 6 Install NGINX Ingress Controller
# echo "Step 6 Installing NGINX Ingress Controller..." | tee -a "${SCRIPT_LOGFILE}"
# kubectl create namespace ingress-nginx || true
# helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx | tee -a "${SCRIPT_LOGFILE}"
# helm repo update | tee -a "${SCRIPT_LOGFILE}"
# helm install ingress-nginx ingress-nginx/ingress-nginx --namespace ingress-nginx | tee -a "${SCRIPT_LOGFILE}"

# # Verify ingress controller
# echo "Step 7 Ingress Controller status:" | tee -a "${SCRIPT_LOGFILE}"
# kubectl get pods -n ingress-nginx | tee -a "${SCRIPT_LOGFILE}"
# kubectl get svc -n ingress-nginx | tee -a "${SCRIPT_LOGFILE}"
