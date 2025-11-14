kit.pgdg.apply() {
  # local ABSOLUTE_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  
  arch=$(dpkg --print-architecture)
  # Add the repo
  # system.debian.repo.custom pgdg \
  system.repository pgdg \
    -k https://www.postgresql.org/media/keys/ACCC4CF8.asc \
    -u http://apt.postgresql.org/pub/repos/apt/ \
    -d "$(lsb_release -cs)-pgdg" \
    -a "$arch" \
    -c main
  
  # Ensure that the pgdg packages are preferred over the built-in packages
  system.file /etc/apt/preferences.d/pgdg.pref \
    -o root \
    -g root \
    -m 644 \
    -s $(kitbash.file /etc/apt/preferences.d/pgdg.pref)
  
  # Enable unattended upgrades
  # Though perhaps this should be an optional, idk
  system.file /etc/apt/apt.conf.d/99unattended-upgrades-pgdg \
    -o root \
    -g root \
    -m 644 \
    -s $(kitbash.file /etc/apt/apt.conf.d/99unattended-upgrades-pgdg)
}
