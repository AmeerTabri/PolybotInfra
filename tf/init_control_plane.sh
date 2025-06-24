#!/bin/bash
set -euo pipefail

# ✅ Load Control Plane IP dynamically from Terraform output
CONTROL_PLANE_IP=$(terraform output -raw control_plane_public_ip)
echo "👉 Control Plane IP: $CONTROL_PLANE_IP"

# ✅ SSH into Control Plane and run kubeadm + Calico setup
ssh -o StrictHostKeyChecking=no ubuntu@$CONTROL_PLANE_IP <<'EOF'
  set -eux

  # 1️⃣ Check if already initialized
  if [ ! -f /etc/kubernetes/admin.conf ]; then
    echo "🚀 Running kubeadm init..."
    sudo kubeadm init --pod-network-cidr=192.168.0.0/16
  else
    echo "✅ Control plane already initialized, skipping kubeadm init."
  fi

  # 2️⃣ Set up kubectl config for ubuntu user
  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

  # 3️⃣ Install Calico CNI if not already installed
  if ! kubectl get daemonset calico-node -n kube-system >/dev/null 2>&1; then
    echo "🚀 Installing Calico CNI..."
    kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.2/manifests/calico.yaml
  else
    echo "✅ Calico already installed, skipping."
  fi

EOF

echo "🎉 Control plane initialization complete!"
