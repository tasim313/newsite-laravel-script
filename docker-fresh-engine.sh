#!/bin/bash

# =========================
# Fresh Docker Engine Setup for Ubuntu
# =========================
set -e

echo "Stopping all Docker containers..."
docker stop $(docker ps -q) 2>/dev/null || true

echo "Removing all Docker containers..."
docker rm $(docker ps -aq) 2>/dev/null || true

echo "Removing all Docker images..."
docker rmi $(docker images -q) 2>/dev/null || true

echo "Removing all Docker volumes..."
docker volume rm $(docker volume ls -q) 2>/dev/null || true

echo "Removing all Docker networks..."
docker network rm $(docker network ls -q) 2>/dev/null || true

echo "Uninstalling old/conflicting Docker packages..."
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras; do
    sudo apt-get purge -y $pkg 2>/dev/null || true
done

echo "Cleaning Docker directories..."
sudo rm -rf /var/lib/docker /var/lib/containerd
sudo rm -f /etc/apt/sources.list.d/docker.list
sudo rm -f /etc/apt/keyrings/docker.asc
sudo rm -rf /etc/apt/keyrings

echo "Installing prerequisites..."
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg lsb-release

echo "Setting up Docker's official GPG key..."
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo "Adding Docker apt repository..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

echo "Updating package index..."
sudo apt-get update

echo "Installing Docker Engine and related packages..."
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "Starting Docker service..."
sudo systemctl enable docker
sudo systemctl start docker

echo "Adding user to Docker group..."
sudo groupadd docker 2>/dev/null || true
sudo usermod -aG docker $USER
newgrp docker

echo "Testing Docker installation..."
docker --version
docker compose version
docker run hello-world || true

echo "Docker Engine fresh setup completed successfully!"

