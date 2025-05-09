#!/bin/bash

# Check if KEY_PATH is set
if [ -z "$KEY_PATH" ]; then
  echo "KEY_PATH env var is expected"
  exit 5
fi

# Check if bastion IP is provided
if [ -z "$1" ]; then
  echo "Please provide bastion IP address"
  exit 5
fi

BASTION_IP="$1"
TARGET_IP="$2"

if [ -n "$TARGET_IP" ]; then
  shift 2
  # Connect to target via bastion
  ssh -i "$KEY_PATH" -o ProxyCommand="ssh -i $KEY_PATH -W %h:%p ubuntu@$BASTION_IP" ubuntu@$TARGET_IP "$@"
else
  # Connect directly to bastion
  ssh -i "$KEY_PATH" ubuntu@$BASTION_IP
fi
