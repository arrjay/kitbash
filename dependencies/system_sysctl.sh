# shellcheck shell=bash

function system::sysctl::runtime () {
  local _sysctl_name=$1  ; shift
  local _sysctl_value=$1 ; shift
  local buf
  __kitbash_log "== ${FUNCNAME[0]} $_sysctl_name"

  sysctl "${_sysctl_name}" >/dev/null 2>&1 || __kitbash_fail "${FUNCNAME[0]}: sysctl does not exist"

  function get_id() {
    echo "${_sysctl_name}"
  }

  function is_met() {
    buf="$(sysctl "${_sysctl_name}")"
    # this should munge linux or freebsd output, at least
    buf="${buf#"${_sysctl_name}"}"
    buf="${buf#": "}"
    buf="${buf#" = "}"
    [[ "${buf}" == "${_sysctl_value}" ]]
  }

  function meet() {
    $__kitbash_sudo sysctl "${_sysctl_name}=${_sysctl_value}"
  }

  process
}

function system::sysctl::persist () {
  local _sysctl_name=$1  ; shift
  local _sysctl_value=$1 ; shift
  local buf
  __kitbash_log "== ${FUNCNAME[0]} $_sysctl_name"

  sysctl "${_sysctl_name}" >/dev/null 2>&1 || __kitbash_fail "${FUNCNAME[0]}: sysctl does not exist"

  function get_id() {
    echo "${_sysctl_name}"
  }

  function is_met() {
    grep -q "^${_sysctl_name}=${_sysctl_value}\$" /etc/sysctl.conf
  }

  function meet() {
    $__kitbash_sudo sed -i .bak -e "/^${_sysctl_name}=/"'!p' -e '$a'"${_sysctl_name}=${_sysctl_value}" /etc/sysctl.conf
    $__kitbash_sudo rm /etc/sysctl.conf.bak
  }

  process
}
