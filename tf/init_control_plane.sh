#!/bin/bash
# This runs locally on the runner and SSHes into EC2

CONTROL_PLANE_IP=$(terraform output -raw control_plane_public_ip)

ssh -o StrictHostKeyChecking=no -i "$SSH_KEY_PATH" ubuntu@$CONTROL_PLANE_IP <<EOF
  sudo kubeadm init --pod-network-cidr=192.168.0.0/16

  mkdir -p \$HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf \$HOME/.kube/config
  sudo chown \$(id -u):\$(id -g) \$HOME/.kube/config

  kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.2/manifests/calico.yaml
EOF
