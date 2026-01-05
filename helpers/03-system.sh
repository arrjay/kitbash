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
  local path uid owner value
  path="$1"
  uid="$2"
  # UID could be either a username _or_ a UID
  # So we should resolve that
  owner=$(user.get_uid "$uid") || return 1
  # and now, check if it matches
  value=$(stat "$stat_flag" '%u' "${path}") || return 1
  [[ "$value" == "$owner" ]]
}

path.has_gid() {
  local path gid group
  path="$1"
  gid="$2"
  group=$(group.get_gid "$gid") || return 1
  local value=$(stat "$stat_flag" '%g' "${path}") || return 1
  [[ "$value" == "$group" ]]
}

path.has_mode() {
  local path mode
  path="$1"
  mode="$2"
  if [[ "${mode:0:1}" == "0" ]]; then
    # Strip the leading 0, as it's implied
    mode="${mode:1}"
  fi
  value=$(stat "$stat_flag" "$stat_mode_format" "${path}") || return 1
  [[ "$value" == "$mode" ]]
}

# OS-specific functions for get_uid and get_gid, to verify the existence of
# groups and users.

local ABSOLUTE_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
system.info.id "macos" && . "$ABSOLUTE_PATH"/system/macos.sh && return
system.info.test "KERNEL" "linux" && . "$ABSOLUTE_PATH"/system/linux.sh && return