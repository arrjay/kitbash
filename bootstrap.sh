#!/bin/bash

if [[ -d /opt/kitbash && -d /opt/kitbash/.git ]]; then
  echo "Found existing kitbash installation; upgrading"
  pushd /opt/kitbash
  sudo git pull
  popd
else
  echo "Cloning new Kitbash installation..."
  sudo git clone \
    --depth 1 \
    --branch kitbash/alpha \
    https://github.com/aurynn/babashka /opt/kitbash > /dev/null 2>&1
fi
[[ -e /usr/bin/babashka ]] || \
  sudo ln -s /opt/kitbash/bin/babashka /usr/bin/babashka
[[ -e /usr/bin/kitbash ]] || \
  sudo ln -s /opt/kitbash/bin/babashka /usr/bin/kitbash

[[ -d /etc/kitbash ]] || \
  sudo mkdir -p /etc/kitbash

# TODO
# Change to "provisioners"? or "builtins"?
[[ -L /etc/kitbash/dependencies ]] || \
  sudo ln -s /opt/kitbash/dependencies /etc/kitbash/dependencies
  
  
[[ -L /etc/kitbash/lib ]] || \
  sudo ln -s /opt/kitbash/helpers /etc/kitbash/lib

if [[ -d /opt/mo ]]; then
  pushd /opt/mo
  sudo git pull
  popd
else
  # "mo" provides the templating engine for Kitbash, when system.file.template is used.
  # This should probably do some kind of version testing?
  sudo git clone https://github.com/tests-always-included/mo.git /opt/mo > /dev/null 2>&1
fi
if ! [[ -e /usr/bin/mo ]]; then
  sudo ln -s /opt/mo/mo /usr/bin/mo
fi
