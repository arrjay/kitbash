#!/bin/bash
sudo apt-get update -y && sudo apt-get install -y gpg sudo wget curl
sudo install -dm 755 /etc/apt/keyrings
wget -qO - https://mise.jdx.dev/gpg-key.pub | gpg --dearmor | sudo tee /etc/apt/keyrings/mise-archive-keyring.gpg 1> /dev/null

arch=$(uname -m)

if [[ "$arch" == "aarch64" ]]; then
  arch="arm64"
fi

echo "deb [signed-by=/etc/apt/keyrings/mise-archive-keyring.gpg arch=${arch}] https://mise.jdx.dev/deb stable main" | sudo tee /etc/apt/sources.list.d/mise.list
sudo apt-get update
sudo apt-get install -y mise