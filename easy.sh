#!/bin/bash

set -e

HTTP_MODE=false
if [ "$1" == "--http" ]; then
  HTTP_MODE=true
fi

if ! command -v docker &> /dev/null
then
  sudo apt update -y
  sudo apt install -y ca-certificates curl gnupg

  sudo install -m 0755 -d /etc/apt/keyrings

  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
    sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

  sudo chmod a+r /etc/apt/keyrings/docker.gpg

  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo \"$VERSION_CODENAME\") stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

  sudo apt update -y

  sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

  echo "docker installed"
fi

mkdir -p ~/wg-easy
cd ~/wg-easy

sudo curl -o docker-compose.yml https://raw.githubusercontent.com/wg-easy/wg-easy/master/docker-compose.yml

WG_HOST=$(curl -fsSL ifconfig.me)

if [ "$HTTP_MODE" = true ]; then
  sed -i 's/^#environment:/environment:/' docker-compose.yml
  sed -i 's/^#  - INSECURE=false/  - INSECURE=true/' docker-compose.yml
fi

# add WG_HOST if environment exists, otherwise create it
if grep -q "^environment:" docker-compose.yml; then
  sed -i "/^environment:/a\  - WG_HOST=${WG_HOST}" docker-compose.yml
else
  sed -i "/wg-easy:/a\    environment:\n      - WG_HOST=${WG_HOST}" docker-compose.yml
fi

sudo docker compose up -d
