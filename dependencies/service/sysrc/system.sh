# shellcheck shell=bash

__internal::system::service::preamble() {
  local _unit="${1}"     ; shift
  local _funcname="${1}" ; shift
  kb_log "== ${_funcname} (sysrc) ${_unit}"

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
  buf="${buf##* }"
  buf="${buf%.}"
  printf '%s\n' "${buf}"
}

system::service::enable() {
  _unit=$1 ; shift

  __internal::system::service::preamble "${_unit}" "${FUNCNAME[0]}"

  function get_id() {
    echo "${_unit}"
  }

  function is_met() {
    service "${_unit}" enabled
  }

  function meet() {
    $__kitbash_sudo sysrc "${_unit}_enable="'YES'
  }

  process
}

system::service::disable() {
  _unit=$1 ; shift

  __internal::system::service::preamble "${_unit}" "${FUNCNAME[0]}"

  function get_id() {
    echo "${_unit}"
  }

  function is_met() {
    service "${_unit}" enabled || return 0
    return 1
  }

  function meet() {
    $__kitbash_sudo sysrc "${_unit}_enable="''
  }

  process
}

system::service::started() {
  _unit=$1 ; shift

  __internal::system::service::preamble "${_unit}" "${FUNCNAME[0]}"

  function get_id() {
    echo "${_unit}"
  }

  function is_met() {
    service "${_unit}" status >/dev/null 2>&1
  }

  # if the service is already running, don't _start_ it.
  function meet() {
    $__kitbash_sudo service "${_unit}" status >/dev/null 2>&1 || $__kitbash_sudo service "${_unit}" onestart
  }

  process
}

system::service::stopped() {
  _unit=$1 ; shift

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

  process
}

system::service::startflags() {
  local _unit=$1  ; shift
  local _flags=$2 ; shift

  __internal::system::service::preamble "${_unit}" "${FUNCNAME[0]}"

  function get_id() {
    printf '%s\n' "${_unit}"
  }

  function get_target() {
    printf 'service:%s\n' "${_unit}"
  }

  function is_met() {
    local buf
    buf="$(sysrc "${_unit}_flags")"
    buf="${buf#"${_unit}_flags: "}"
    [[ "${buf}" == "${_flags}" ]]
  }

  function meet() {
    $__kitbash_sudo sysrc "${_unit}_flags="'"'"${_flags}"'"'
  }
}

helper::system::service::restart() {
  local _unit=$1 ; shift

  __internal::system::service::preamble "${_unit}" "${FUNCNAME[0]}"

  $__kitbash_sudo service "${_unit}" onerestart >/dev/null 2>&1
  st="${?}"

  return "${st}"
}
