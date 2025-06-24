#!/bin/bash
set -eux

CONTROL_PLANE_IP=$1
SSH_KEY_PATH=$2

ssh -o StrictHostKeyChecking=no -i "$SSH_KEY_PATH" ubuntu@$CONTROL_PLANE_IP <<EOF
  sudo kubeadm init --pod-network-cidr=192.168.0.0/16

  mkdir -p \$HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf \$HOME/.kube/config
  sudo chown \$(id -u):\$(id -g) \$HOME/.kube/config

  kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.2/manifests/calico.yaml
EOF
