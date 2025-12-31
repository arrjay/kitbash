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
  
  local group owner mode _source contents
  # Set defaults
  group=root
  owner=root
  mode="644"
  
  declare -a XOR=( "--source,--contents" )
  
  while getopts "g:o:m:s:c:" opt; do
    case "$opt" in
      g)
        group=$(echo $OPTARG | xargs);;
      o)
        owner=$(echo $OPTARG | xargs);;
      m)
        mode=$(echo $OPTARG | xargs);;
      s)
        _source=$(echo $OPTARG | xargs);;
      c)
        contents=$(echo $OPTARG | xargs);;
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
    
    if [[ -n "${_source}" ]]; then
      
      std.file.check "$_file_name" \
        source "$_source" \
        mode "$mode" \
        owner "$owner" \
        group "$group"
      return $?
      
    elif [[ -n "$contents" ]]; then
      std.file.check "$_file_name" \
        contents "$contents" \
        mode "$mode" \
        owner "$owner" \
        group "$group"
      return $?
    else
      # that's an error, at least one of these needs to be set
      kitbash.fail "$_file_name: one of source or contents must be set"
    fi
    return 0
  }
  meet() {
    if [[ -n "${_source}" ]]; then
      
      std.file.update "$_file_name" \
        source "$_source" \
        mode "$mode" \
        owner "$owner" \
        group "$group"
      return $?
      
    elif [[ -n "$contents" ]]; then
      std.file.update "$_file_name" \
        contents "$contents" \
        mode "$mode" \
        owner "$owner" \
        group "$group"
      return $?
    fi
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
