# Common functions

# Switch based on which `stat` we're using.
# Non-Linux systems probably won't have GNU `stat` by default.
stat_flag=""
stat_mode_format=""
if stat --version &>/dev/null; then
  # GNU stat
  stat_flag="-c"
  stat_mode_format='%a'
else
  # BSD/macOS
  stat_flag="-f"
  stat_mode_format='%Lp'
fi

path.has_uid() {
  local _path="$1"
  local _uid="$2"
  # UID could be either a username _or_ a UID
  # So we should resolve that
  local _owner=$(user.get_uid "$_uid") || return 1
  # and now, check if it matches
  local value=$(stat "$stat_flag" '%u' "${_path}") || return 1
  [[ "$value" == "$_owner" ]]
}

path.has_gid() {
  local _path="$1"
  local _gid="$2"
  local _group=$(group.get_gid "$_gid") || return 1
  local value=$(stat "$stat_flag" '%g' "${_path}") || return 1
  [[ "$value" == "$_group" ]]
}

path.has_mode() {
  local _path="$1"
  local _mode="$2"
  if [[ "${_mode:0:1}" == "0" ]]; then
    # Strip the leading 0, as it's implied
    _mode="${_mode:1}"
  fi
  value=$(stat "$stat_flag" "$stat_mode_format" "${_path}") || return 1
  [[ "$value" == "$_mode" ]]
}

# OS-specific functions for get_uid and get_gid, to verify the existence of
# groups and users.

local ABSOLUTE_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
system::info::id "macos" && . "$ABSOLUTE_PATH"/system/macos.sh && return
system::info::test "KERNEL" "linux" && . "$ABSOLUTE_PATH"/system/linux.sh && return