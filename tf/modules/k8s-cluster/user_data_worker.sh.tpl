#!/bin/bash
set -eux

# Install AWS CLI and jq
apt-get update && apt-get install -y awscli jq

# Get the join command from Secrets Manager
JOIN_CMD=$(aws secretsmanager get-secret-value --region ${region} --secret-id ${secret_name} | jq -r '.SecretString')

# Run it
$JOIN_CMD
