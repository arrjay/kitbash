#!/bin/bash

# Clean up environment
# echo "Removing i386 from dpkg"
# sudo dpkg --remove-architecture i386

export DEBIAN_FRONTEND=noninteractive
export DEBCONF_NONINTERACTIVE_SEEN=true

cat <<EOF | sudo tee /etc/apt/apt.conf.d/00-norecommends.conf > /dev/null
APT::Install-Recommends "false";
APT::Install-Suggests "false"; 
EOF

sudo rm -f /etc/apt/apt.conf.d/70debconf

# sudo dpkg-preconfigure -f noninteractive -p critical

DEBIAN_FRONTEND=noninteractive sudo apt-get -qq -y clean > /dev/null
echo "Doing initial apt-get updates"
DEBIAN_FRONTEND=noninteractive sudo apt-get -qq -y update > /dev/null
# DEBIAN_FRONTEND=noninteractive sudo apt-get -qq -y install apt-utils > /dev/null
echo "Attempting upgrade..."
DEBIAN_FRONTEND=noninteractive sudo apt-get -qq -y upgrade > /dev/null
# DEBIAN_FRONTEND=noninteractive sudo apt-get -qq -y install net-tools  > /dev/null
DEBIAN_FRONTEND=noninteractive sudo apt-get -qq -y autoremove > /dev/null

echo "Installing git and gpg"
DEBIAN_FRONTEND=noninteractive sudo apt-get -qq -y install git gpg > /dev/null