#!/bin/bash
set -e

echo "✅ Deploying NGINX container..."

# Create conf.d directory if it doesn't exist
mkdir -p /home/ubuntu/conf.d

# Stop and remove old container if it exists
docker stop mynginx || true
docker rm mynginx || true

# Run NGINX container with mounted configs and certs
docker run -d --restart always --name mynginx \
  -p 443:443 \
  -v /home/ubuntu/conf.d:/etc/nginx/conf.d \
  -v /etc/letsencrypt:/etc/letsencrypt:ro \
  nginx
