if [[ -d /opt/mo ]]; then
  pushd /opt/mo
  sudo git pull
  popd
else
  sudo git clone https://github.com/tests-always-included/mo.git /opt/mo
fi
if ! [[ -e /usr/bin/mo ]]; then
  sudo ln -s /opt/mo/mo /usr/bin/mo
fi