# shellcheck shell=bash
# Manage systemd units

system::service::enable() {
  local _unit=$1; shift

  __babashka_log "== ${FUNCNAME[0]} (systemd) $_unit"
  # check if the unit even exists; if it doesn't this makes no sense
  if systemctl is-enabled "$_unit" 2>&1 | grep -q "No such file or directory" ; then
    __babashka_fail "${FUNCNAME[0]} (systemd): Unit $_unit not installed"
  fi

  function get_id() {
    echo "${_unit}"
  }

  is_met() {
    # how do we check if a systemd service is enabled?
    systemctl is-enabled "$_unit" | grep -q "enabled"
  }
  meet() {
    $__babashka_sudo systemctl enable "$_unit" > /dev/null 2>&1;
  }
  process
}

system::service::disable() {
  local _unit=$1; shift
  __babashka_log "== ${FUNCNAME[0]} (systemd)  $_unit"

  # check if the unit even exists; if it doesn't this makes no sense
  if systemctl is-enabled "$_unit" 2>&1 | grep -q "No such file or directory" ; then
    __babashka_fail "${FUNCNAME[0]} (systemd): Unit $_unit not installed"
  fi

  function get_id() {
    echo "${_unit}"
  }

  is_met() {
    # how do we check if a systemd service is enabled?
    systemctl is-enabled "$_unit" | grep -q "disabled"
  }
  meet() {
    $__babashka_sudo systemctl disable "$_unit" > /dev/null 2>&1;
  }
  process
}

# TODO: what does a failed service look like?
system::service::started() {
  local _unit=$1; shift

  __babashka_log "== ${FUNCNAME[0]} (systemd) $_unit"
  # check if the unit even exists; if it doesn't this makes no sense
  if systemctl is-enabled "$_unit" 2>&1 | grep -q "No such file or directory" ; then
    __babashka_fail "${FUNCNAME[0]} (systemd): Unit $_unit not installed"
  fi

  function get_id() {
    echo "${_unit}"
  }

  is_met() {
    systemctl show --property ActiveState --value "$_unit" | grep -q "active"
  }
  meet() {
    $__babashka_sudo systemctl start "$_unit" > /dev/null 2>&1;
  }
  process
}

system::service::stopped() {
  local _unit=$1; shift

  __babashka_log "== ${FUNCNAME[0]} (systemd) $_unit"
  # check if the unit even exists; if it doesn't this makes no sense
  if systemctl is-enabled "$_unit" 2>&1 | grep -q "No such file or directory" ; then
    __babashka_fail "${FUNCNAME[0]} (systemd): Unit $_unit not installed"
  fi

  function get_id() {
    echo "${_unit}"
  }

  is_met() {
    systemctl show --property ActiveState --value "$_unit" | grep -q "inactive"
  }
  meet() {
    $__babashka_sudo systemctl stop "$_unit" > /dev/null 2>&1;
  }
}
