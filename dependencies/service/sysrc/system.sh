# shellcheck shell=bash

system::service::enable() {
  local _unit=$1 ; shift
  __kitbash_log "== ${FUNCNAME[0]} (sysrc) $_unit"
  local exists=0 ; svc
  for svc in /etc/rc.d/${_unit} /usr/local/etc/rc.d/${_unit} ; do [[ -x "${svc}" ]] && exists=1 ; done
  [[ "${exists}" -eq 1 ]] || __kitbash_file "${FUNCNAME[0]} (sysrc): Unit $_unit not installed"

  function get_id() {
    echo "${_unit}"
  }

  function is_met() {
    service "${_unit}" enabled
  }

  function meet() {
    $__kitbash_sudo sysrc "${_unit}_enable="'"YES"'
  }

  process
}

system::service::disable() {
  local _unit=$1 ; shift
  __kitbash_log "== ${FUNCNAME[0]} (sysrc) $_unit"
  local exists=0 ; local svc
  for svc in /etc/rc.d/${_unit} /usr/local/etc/rc.d/${_unit} ; do [[ -x "${svc}" ]] && exists=1 ; done
  [[ "${exists}" -eq 1 ]] || __kitbash_file "${FUNCNAME[0]} (sysrc): Unit $_unit not installed"

  function get_id() {
    echo "${_unit}"
  }

  function is_met() {
    service "${_unit}" enabled || return 0
    return 1
  }

  function meet() {
    $__kitbash_sudo sysrc "${_unit}_enable="'""'
  }
}

system::service::started() {
  local _unit=$1 ; shift
  __kitbash_log "== ${FUNCNAME[0]} (sysrc) $_unit"
  local exists=0 ; svc
  for svc in /etc/rc.d/${_unit} /usr/local/etc/rc.d/${_unit} ; do [[ -x "${svc}" ]] && exists=1 ; done
  [[ "${exists}" -eq 1 ]] || __kitbash_file "${FUNCNAME[0]} (sysrc): Unit $_unit not installed"

  function get_id() {
    echo "${_unit}"
  }

  function is_met() {
    service "${_unit}" status >/dev/null 2>&1
  }

  function meet() {
    $__kitbash_sudo service "${_unit}" onestart
  }
}

system::service::stopped() {
  local _unit=$1 ; shift
  __kitbash_log "== ${FUNCNAME[0]} (sysrc) $_unit"
  local exists=0 ; svc
  for svc in /etc/rc.d/${_unit} /usr/local/etc/rc.d/${_unit} ; do [[ -x "${svc}" ]] && exists=1 ; done
  [[ "${exists}" -eq 1 ]] || __kitbash_file "${FUNCNAME[0]} (sysrc): Unit $_unit not installed"

  function get_id() {
    echo "${_unit}"
  }

  function is_met() {
    service "${_unit}" status >/dev/null 2>&1 || return 0
    return 1
  }

  function meet() {
    $__kitbash_sudo service "${_unit}" stop
  }
}
