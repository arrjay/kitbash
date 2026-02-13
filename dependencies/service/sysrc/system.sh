# shellcheck shell=bash

__internal::system::service::preamble() {
  local _unit="${1}"     ; shift
  local _funcname="${1}" ; shift
  __kitbash_log "== ${_funcname} (sysrc) ${_unit}"

  # check if the unit even exists; if it doesn't this makes no sense
  local exists=0 ; local svc
  for svc in /etc/rc.d/${_unit} /usr/local/etc/rc.d/${_unit} ; do [[ -x "${svc}" ]] && exists=1 ; done
  [[ "${exists}" -eq 1 ]] || __kitbash_fail "${funcname} (sysrc): Unit $_unit not installed"
}

fact::system::service::mainpid() {
  local _unit=$1 ; shift
  local buf

  __internal::system::service::preamble "${_unit}" "${FUNCNAME[0]}"

  # this assumes 'typical' "foo is running as pid XXXX."
  buf="$(service "${_unit}" status)"
  buf="${buf## *}"
  buf="${buf%.}"
  printf '%s\n' "${buf}"
}

system::service::enable() {
  local _unit=$1 ; shift

  __internal::system::service::preamble "${_unit}" "${FUNCNAME[0]}"

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

  __internal::system::service::preamble "${_unit}" "${FUNCNAME[0]}"

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

  __internal::system::service::preamble "${_unit}" "${FUNCNAME[0]}"

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

  __internal::system::service::preamble "${_unit}" "${FUNCNAME[0]}"

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
