# shellcheck shell=bash

# does this create a function? is that how this works? How does this even work?

# Helpers:
# These work by returning success (or not) in a is_met block, which can then
# trigger a meet block _to_ run. They are not workable as full kitbash
# realizations, but 'help' abstract annoying bits away.
# This also means they _should_ use locals and not step on the global variable
# space where possible. A helper wrecking a realization would be...bad.
# Facts:
# These may return success of failure, but they *also* are returning targeted
# data about...something. They largely work under the same constraints as
# helpers, just they say other things too.
# Facts say things.
# Helpers should be silent and use return codes.

fact::user::uid() {
  local _user="${1}"; shift
  local _uid

  # If it's blank then we can't do anything useful
  [[ "${_user}" ]] || return 1

  case "${_user}" in
    *[!0-9]*)
      # Is a string, so we need to check if the group even exists
      # And if it doesn't, that's, well, bad? Yes, that's bad.
      _uid="$(getent passwd "${_user}")"
      _uid="${_uid#*:*}"
      _uid="${_uid%%:*}"
      ;;
    *)
      # is a number
      # We can pass it on directly
      _uid="${_user}"
      ;;
  esac

  printf '%s\n' "${_uid}"
}

__compat_shim "called legacy user.get_uid" user.get_uid fact::user::uid

fact::group::gid() {
  local _group_name="${1}"; shift
  local _gid

  # If it's blank then we can't do anything useful
  [[ "${_group_name}" ]] || return 1

  case "${_group_name}" in
    *[!0-9]*)
      # Is a string, so we need to check if the group even exists
      # And if it doesn't, that's, well, bad? Yes, that's bad.
      _gid="$(getent group "${_group_name}")"
      _gid="${_gid#*:*}"
      _gid="${_gid%%:*}"
      ;;
    *)
      # is a number
      # We can pass it on directly
      _gid="${_group_name}"
      ;;
  esac

  printf '%s\n' "${_gid}"
}

__compat_shim "called legacy group.get_gid" group.get_gid fact::group::gid

# slight curve here - the previous path functions were more in the helper category
# and we've split some of the lift into the facts, which never existed before.
fact::path::uid() {
  local _path="${1}"; shift
  local buf

  buf="$(stat -c '%u' "${_path}")"

  [[ "${buf}" ]] || return 1
  printf '%s\n' "${buf}"
}

helper::path::owner() {
  local _path="${1}"  ; shift
  local _owner="${1}" ; shift
  local _uid

  # UID could be either a username _or_ a UID
  # So we should resolve that
  _uid="$(fact::user::uid "${_owner}")"

  [[ "${_uid}" == "" ]] && __kitbash_fail "user cannot be resolved"

  [[ "$(fact::path::uid "${_path}")" == "${_uid}" ]]
}

__compat_shim "called legacy path.has_uid" path.has_uid helper::path::owner

fact::path::gid() {
  local _path="${1}" ; shift
  local buf

  buf="$(stat -c '%g' "${_path}")"

  [[ "${buf}" ]] || return 1
  printf '%s\n' "${buf}"
}

helper::path::group() {
  local _path="${1}" ; shift
  local _group="${1}"  ; shift
  local _gid

  _gid="$(fact::group::gid "${_group}")"

  [[ "${_gid}" == "" ]] && __kitbash_fail "group cannot be resolved"

  [[ "$(fact::path::gid "${_path}")" == "${_gid}" ]]
}

__compat_shim "called legacy path.has_gid" path.has_gid helper::path::group

fact::path::mode() {
  local _path="${1}" ; shift
  local buf

  buf="$(stat -c '%s' "${_path}")"

  [[ "${buf}" ]] || return 1
  printf '%s\n' "${buf}"
}

helper::path::mode() {
  local _path="${1}" ; shift
  local _mode="${1}" ; shift

  # Strip the leading 0 for 4-octet modes, as it's implied
  [[ "${#_mode}" -eq 4 ]] && [[ "${_mode:0:1}" == "0" ]] && _mode="${_mode:1}"

  [[ "$(fact::path::mode "${_path}")" == "${_mode}" ]]
}

__compat_shim "called legacy path.has_mode" path.has_mode helper::path::mode
