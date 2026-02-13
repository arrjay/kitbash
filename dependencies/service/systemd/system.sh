# shellcheck shell=bash
# Manage systemd units

# this is *not* intended for external use.
__internal::system::service::preamble() {
  local _unit=$1     ; shift
  local _funcname=$1 ; shift
  __babashka_log "== ${_funcname} (systemd) $_unit"

  # check if the unit even exists; if it doesn't this makes no sense
  if systemctl is-enabled "$_unit" 2>&1 | grep -q "No such file or directory" ; then
    __babashka_fail "${_funcname} (systemd): Unit $_unit not installed"
  fi
}

# this *is* intended for external use, but is not...a direct state?
# it's intended to help connect what's running with what's configured.
# as a result there is no get_id/is_met/meet/process at all.
fact::system::service::mainpid() {
  local _unit=$1; shift

  __internal::system::service::preamble "${FUNCNAME[0]}" "$_unit"

  systemctl show --property MainPID --value "${_unit}"
}

system::service::enable() {
  local _unit=$1; shift

  __internal::system::service::preamble "${FUNCNAME[0]}" "$_unit"

  function get_id() {
    echo "${_unit}"
  }

  is_met() {
    systemctl is-enabled "$_unit" | grep -q "enabled"
  }
  meet() {
    $__babashka_sudo systemctl enable "$_unit" > /dev/null 2>&1;
  }
  process
}

system::service::disable() {
  local _unit=$1; shift

  __internal::system::service::preamble "${FUNCNAME[0]}" "$_unit"

  function get_id() {
    echo "${_unit}"
  }

  is_met() {
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

  __internal::system::service::preamble "${FUNCNAME[0]}" "$_unit"

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

  __internal::system::service::preamble "${FUNCNAME[0]}" "$_unit"

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
