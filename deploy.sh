#!/bin/bash

# Deployment Script for DarkModeToggle React App
# This script builds the app, creates a Docker image, and deploys to production via Nginx

# === Configuration ===
APP_NAME="dark-mode-app"
IMAGE_NAME="$APP_NAME:latest"
REGISTRY="docker.io"
REPO_NAME="axlebucamp/dark-mode-toggle"
CONTAINER_NAME="dark-mode-app"
NGINX_CONFIG_PATH="/etc/nginx/nginx.conf"
APP_DIR="/app"

# === Build and Docker Image ===
echo "[INFO] Building React app in production mode..."

# Ensure the app directory exists
if [ ! -d "$APP_DIR" ]; then
  echo "[ERROR] Application directory not found: $APP_DIR" >&2
  exit 1
fi

# Build the app (assumes npm run build is available)
if ! npm run build; then
  echo "[ERROR] Failed to build React app" >&2
  exit 1
fi

# Create Docker image
echo "[INFO] Building Docker image: $IMAGE_NAME..."

docker build -t "$IMAGE_NAME" .

# Check if image was created
if [ $? -ne 0 ]; then
  echo "[ERROR] Docker build failed" >&2
  exit 1
fi

# === Push to Docker Registry ===
echo "[INFO] Pushing image to $REGISTRY/$REPO_NAME..."

docker tag "$IMAGE_NAME" "$REGISTRY/$REPO_NAME:$IMAGE_NAME"

docker push "$REGISTRY/$REPO_NAME:$IMAGE_NAME"

# Check if push was successful
if [ $? -ne 0 ]; then
  echo "[ERROR] Failed to push image to registry" >&2
  exit 1
fi

# === Deploy to Production Environment ===
echo "[INFO] Deploying container to production..."

# Stop existing container if it exists
if docker ps --filter name=$CONTAINER_NAME --format "{{.Names}}" | grep -q $CONTAINER_NAME; then
  echo "[INFO] Stopping existing container: $CONTAINER_NAME"
  docker stop $CONTAINER_NAME
fi

# Remove old container
if docker ps --filter name=$CONTAINER_NAME --format "{{.Names}}" | grep -q $CONTAINER_NAME; then
  echo "[INFO] Removing old container: $CONTAINER_NAME"
  docker rm $CONTAINER_NAME
fi

# Run new container
echo "[INFO] Starting new container: $CONTAINER_NAME"

docker run -d --name $CONTAINER_NAME -p 3000:3000 $IMAGE_NAME

# === Configure Nginx ===
echo "[INFO] Updating Nginx configuration..."

# Copy updated nginx.conf to server
# (This assumes Nginx is accessible and configured to reload)
# In production, you would run:
# sudo cp nginx.conf /etc/nginx/nginx.conf
# sudo nginx -t && sudo systemctl reload nginx

# === Health Check & Monitoring ===
echo "[INFO] Health check: Waiting for container to start..."

# Wait for container to be ready (optional timeout)
timeout 60s docker logs $CONTAINER_NAME | grep -q "Server running" && echo "[SUCCESS] Container is running and healthy." || {
  echo "[ERROR] Container failed to start or is not healthy" >&2
  exit 1
}

# === Final Output ===
echo "[DEPLOYMENT COMPLETE]" 
echo "  - Image: $REGISTRY/$REPO_NAME:$IMAGE_NAME"
echo "  - Container: $CONTAINER_NAME"
echo "  - URL: https://darkmode-toggle.example.com"

# Optional: Notify via email or Slack
# echo "Deployment successful!" | curl -X POST -H 'Content-type: application/json' -d '{"text": "Deployment successful!"}' https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXXXXXX

# === Cleanup ===
# Optional: Remove build artifacts
# rm -rf build/