#!/bin/bash
set -eux

# Install AWS CLI and jq
apt-get update && apt-get install -y awscli jq

# Get the join command from Secrets Manager
JOIN_CMD=$(aws secretsmanager get-secret-value --region ${region} --secret-id ${secret_name} | jq -r '.SecretString')

# Run it
$JOIN_CMD


##!/bin/bash
#set -eux
#
## Install AWS CLI v2 and jq
#sudo apt-get update
#sudo apt-get install -y unzip jq
#curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
#unzip awscliv2.zip
#sudo ./aws/install --update
#
## Get the join command from Secrets Manager
#JOIN_CMD=$(aws secretsmanager get-secret-value --region us-west-2 --secret-id kubeadm-join-command | jq -r '.SecretString')
#
## Run it as root
#sudo bash -c "$JOIN_CMD"

