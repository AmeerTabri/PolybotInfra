#!/bin/bash
set -eux  # Strict error + log

echo "Hello" > /home/ubuntu/k1.txt
echo "Hello" > /home/ubuntu/k1.7.txt

KUBERNETES_VERSION=v1.32

# Base packages
sudo apt-get update
sudo apt-get install -y jq unzip ebtables ethtool curl apt-transport-https ca-certificates gpg software-properties-common

echo "Hello" > /home/ubuntu/k2.txt

# Install awscli
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

echo "Hello" > /home/ubuntu/k3.txt

# Enable IPv4 forwarding
echo "net.ipv4.ip_forward = 1" | sudo tee /etc/sysctl.d/k8s.conf
sudo sysctl --system

echo "Hello" > /home/ubuntu/k4.txt

# ✅ Always ensure keyrings folder exists:
sudo mkdir -p /etc/apt/keyrings

echo "Hello" > /home/ubuntu/k5.txt

# ✅ Add Kubernetes repo with key:
curl -fsSL https://pkgs.k8s.io/core:/stable:/${KUBERNETES_VERSION}/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/${KUBERNETES_VERSION}/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list

echo "Hello" > /home/ubuntu/k6.txt

# ✅ Add CRI-O repo with key:
curl -fsSL https://pkgs.k8s.io/addons:/cri-o:/prerelease:/main/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/cri-o-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/cri-o-apt-keyring.gpg] https://pkgs.k8s.io/addons:/cri-o:/prerelease:/main/deb/ /" | sudo tee /etc/apt/sources.list.d/cri-o.list

echo "Hello" > /home/ubuntu/k7.txt


# Clean, update, wait, then install:
sudo apt-get clean
sudo apt-get update
sleep 2
sudo apt-get install -y cri-o kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

echo "Hello" > /home/ubuntu/k8.txt

# Enable services
sudo systemctl enable --now crio
sudo systemctl enable --now kubelet

echo "Hello" > /home/ubuntu/k9.txt

# Disable swap now + persist
sudo swapoff -a
(crontab -l 2>/dev/null; echo "@reboot /sbin/swapoff -a") | crontab -

echo "Hello" > /home/ubuntu/k10.txt