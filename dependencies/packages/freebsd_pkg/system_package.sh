# shellcheck shell=bash

function system::package() {
  local _package_name=$1; shift
  # "all configuration options from pkg.conf(5) can be passed as environment variables."
  __kitbash_log "== ${FUNCNAME[0]} (pkg) $_package_name"
  function get_id() {
    echo "${_package_name}"
  }
   function is_met() {
     pkg info "${_package_name}" >/dev/null 2>&1
   }
   function meet() {
     $__kitbash_sudo pkg install -y "${_package_name}"
   }
  process
}

function system::package::absent() {
  local _package_name=$1; shift
  __kitbash_log "== ${FUNCNAME[0]} (pkg) $_package_name"
  function get_id() {
    echo "${_package_name}"
  }
   function is_met() {
     pkg info "${_package_name}" >/dev/null 2>&1 && return 1
     return 0
   }
   function meet() {
     pkg remove -y "${_package_name}"
     pkg autoremove -y
   }
  process
}
