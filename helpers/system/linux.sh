# does this create a function? is that how this works? How does this even work?

system::info::test "KERNEL" "linux" || return

user.get_uid() {
  local user="$1"
  [[ -z "$user" ]] && return 1
  
  local entry
  entry=$(getent passwd "$user") || return 1
  
  local _name _passwd _uid _gid _gecos _home _shell
  IFS=':' read -r _name _passwd _uid _gid _gecos _home _shell <<< "$entry"
  
  printf '%s' "$_uid"
}

group.get_gid() {
  local _group_name="$1"
  
  [[ -z "$_group_name" ]] && return 1
  
  local entry
  entry=$(getent group "$_group_name") || return 1
  
  IFS=':' read -r _name _passwd _gid _members <<< "$entry"
  
  printf '%s' "$_gid"
}

