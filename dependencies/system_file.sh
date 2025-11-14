# Manages a file on disk somewhere

system.file() {
  local _file_name=$1; shift
  # g: gid or group name
  # u: uid or username
  # s: source (optional)
  # c: contents (optional(?))
  # TODO: Use `getopt` instead to allow more betterer parsing?
  #       Though getopt is often confusing
  #       oh well
  
  declare -A OPTIONS=(
    ["-s|--source;string"]=""
    ["-m|--mode;mode"]="0644"
    ["-o|--owner;string"]="root"
    ["-g|--group;string"]="root"
    ["-c|--contents;string"]=""
  )
  
  declare -a XOR=( "--source,--contents" )
  
  while getopts "g:o:m:s:c:" opt; do
    case "$opt" in
      g)
        local group=$(echo $OPTARG | xargs);;
      o)
        local owner=$(echo $OPTARG | xargs);;
      m)
        local mode=$(echo $OPTARG | xargs);;
      s)
        local _source=$(echo $OPTARG | xargs);;
      c)
        local contents=$(echo $OPTARG | xargs);;
    esac
  done
  unset OPTIND
  unset OPTARG
  __babashka_log "== ${FUNCNAME[0]} $_file_name"
  
  get_id() {
    echo "${_file_name}"
  }

  is_met() {
    # __babashka_log "file name: $_file_name"
    ! [[ -e "$_file_name" ]] && return 1

    if [[ -n "$group" ]]; then
      path.has_gid "$_file_name" "$group" || return 1
    fi
    if [[ -n "$owner" ]]; then
      path.has_uid "$_file_name" "$owner" || return 1
    fi
    if [[ -n "$mode" ]]; then
      path.has_mode "$_file_name" "$mode" || return 1
    fi
    # Okay the basic mode stuff is set up properly
    # (though ideally this'd be a helper function instead of C&P from system.directory)
    # TODO I guess?
    # Okay anyway check contents now

    if [[ -n "${_source}" ]]; then
      # okay we're using source
      # We might need sudo privs to read the file
      $__babashka_sudo diff "$_file_name" "$_source"
      return $?
    elif [[ -n "$contents" ]]; then
      # Use contents
      # We might need sudo privs to read the file
      echo "$contents" | $__babashka_sudo diff "$_file_name" -
      return "$?"
    else
      # that's an error, at least one of these needs to be set
      __babashka_fail "${FUNCNAME[0]} $_file_name: one of source or contents must be set"
    fi
    return 0
  }
  meet() {
    if [[ -n "${_source}" ]]; then
      $__babashka_sudo cp "$_source" "$_file_name"
    elif [[ -n "$contents" ]]; then
      # Do it quietly
      echo "$contents" | $__babashka_sudo tee "$_file_name" > /dev/null
    else
      # Fail
      return 1;
    fi
    
    if [[ -n "$mode" ]]; then 
      $__babashka_sudo chmod "$mode" "$_file_name" || return 1
    fi
    if [[ -n "$owner" ]]; then 
      $__babashka_sudo chown "$owner" "$_file_name" || return 1
    fi
    if [[ -n "$group" ]]; then 
      $__babashka_sudo chgrp "$group" "$_file_name" || return 1
    fi
    return 0
  }
  process
}

system.file.line() {
  local _file="$1"; shift
  while getopts "c:" opt; do
    case "$opt" in
      c)
        local _contents="$OPTARG";;
    esac
  done
  unset OPTIND
  unset OPTARG
  __babashka_log "== ${FUNCNAME[0]} $_file $_contents"
  get_id() {
    echo "${_file}"
  }
  is_met() {
    # Check the beginning of the line
    $__babashka_sudo grep "^$_contents" "$_file"
  }
  meet() {
    echo "$_contents" | $__babashka_sudo tee -a "$_file"
  }
  echo "system.file.line ${FUNCNAME[*]}"
  process
}

# Ensure a file does not exist
system.file.absent() {
  local _file="$1"; shift;
  __babashka_log "== ${FUNCNAME[0]} $_file"
  if [[ -d "$_file" ]]; then
    __babashka_fail "ERROR: $_file is a directory"
  fi
  get_id() {
    echo "${_file}"
  }
  is_met() {
    ! [[ -e "$_file" ]];
  }
  meet() {
    $__babashka_sudo rm "$_file";
  }
  echo "system.file.absent ${FUNCNAME[*]}"
  process
}
