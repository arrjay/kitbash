# shellcheck shell=bash

function system::directory() {
  local _directory=$1;
  shift
  while getopts "o:g:m:" opt; do
    case "$opt" in
      o)
        local owner=$(echo $OPTARG | xargs);;
      g)
        local group=$(echo $OPTARG | xargs);;
      m)
        local mode=$(echo $OPTARG | xargs);;
    esac
  done
  # Reset the option parsing
  unset OPTIND
  unset OPTARG
  kb_log "== ${FUNCNAME[0]} $_directory"
  function get_id() {
    printf '%s\n' "${_directory}"
  }
  function get_target() {
    printf 'directory:%s\n' "${_directory}"
  }
  function is_met() {
    [[ -d "${_directory}" ]]
    { [[ "${owner}" ]] && { helper::path::owner "${_directory}" "${owner}" || return 1 ; } ; } || :
    { [[ "${group}" ]] && { helper::path::group "${_directory}" "${group}" || return 1 ; } ; } || :
    { [[ "${mode}"  ]] && { helper::path::mode  "${_directory}" "${mode}"  || return 1 ; } ; } || :
  }
  function meet() {
    # Create parents automatically
    # TODO: could we use install here instead?
    ! [[ -d "${_directory}" ]] && $__babashka_sudo mkdir -p "${_directory}"
    [[ "${owner}" ]] && $__babashka_sudo chown "${owner}" "${_directory}"
    [[ "${group}" ]] && $__babashka_sudo chgrp "${group}" "${_directory}"
    [[ "${mode}"  ]] && $__babashka_sudo chmod "${mode}"  "${_directory}"
    return 0
  }
  process
}

__compat_shim "called legacy system.directory" system.directory system::directory

# function system.directory.sync() {
#   local _directory=$1;
#   shift
#   while getopts "o:g:m" opt; do
#     case "$opt" in
#       o)
#         local owner=$(echo $OPTARG | xargs);;
#       g)
#         local group=$(echo $OPTARG | xargs);;
#       m)
#         local mode=$(echo $OPTARG | xargs);;
#       s)
#         local _source=$(echo $OPTARG | xargs);;
#     esac
#   done
#   unset OPTIND
#   unset OPTARG
#   __babashka_log "system.directory $_directory"
#   function is_met() {
#
#   }
#   function meet() {
#
#   }
# }
