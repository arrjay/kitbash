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
# helpers, just they say other things too. Helpers should be silent.

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

group.get_gid() {
  _group_name=$1; shift
  if [[ $_group_name != "" ]]; then
    case $_group_name in
      *[!0-9]*)
        # Is a string, so we need to check if the group even exists
        # And if it doesn't, that's, well, bad? Yes, that's bad.
        _gid=$(getent group $_group_name | awk -F ':' '{print $3}')
        ;;
      *)
        # is a number
        # We can pass it on directly
        _gid=$gid
        ;;
    esac
    echo $_gid
  else
    return -1
  fi
}

path.has_uid() {
  _path=$1; shift
  _uid=$1; shift
  _owner=$(user.get_uid $_uid)
  # UID could be either a username _or_ a UID
  # So we should resolve that
  if [[ $_owner != "" ]] && [[ `stat -c '%u' ${_path}` != $_owner ]]; then
    return 1
  fi
  return 0
}

path.has_gid() {
  _path=$1; shift
  _gid=$1; shift
  _group=$(group.get_gid $_gid)
  if [[ $_group != "" ]] && [[ `stat -c '%g' ${_path}` != $_group ]]; then
    return 1
  fi
  return 0
}

path.has_mode() {
  _path=$1; shift
  _mode=$1; shift
  if [[ ${_mode:0:1} == "0" ]]; then
    # Strip the leading 0, as it's implied
    _mode="${_mode:1}"
  fi
  [[ `stat -c '%a' ${_path}` != $_mode ]] && return 1
  return 0
}
