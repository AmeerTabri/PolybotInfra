#!/bin/bash
set -e

echo "✅ Deploying NGINX container..."

# Create conf.d directory if it doesn't exist
mkdir -p /home/ubuntu/conf.d

# Stop and remove old container if exists
docker stop mynginx || true
docker rm mynginx || true

# Run NGINX container
docker run -d --name mynginx \
  -p 443:443 \
  -v /home/ubuntu/conf.d:/etc/nginx/conf.d/ \
  -v /home/ubuntu/certs:/etc/nginx/certs \
  nginx
