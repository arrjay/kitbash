bb.file.content.match() {
  local _filename="$1"; shift
  # _contents=$1; shift
  echo "$@" | diff "$_filename" -
}

std.file.matches() {
  /usr/bin/diff "$1" "$2"
}

std.file.has_content() {
  log.debug "testing $1 for $2"
  /bin/echo "$2" | diff "$1" -
  local result="$?"
  log.debug "got result $result"
  return "$result"
}

std.file.check() {
  local _filename="$1"; shift
  log.debug "checking $_filename"
  declare -A OPTIONS=(
    ["s|source;string"]=""
    ["m|mode;mode"]="644"
    ["o|owner;string"]="root"
    ["g|group;string"]="root"
    ["c|contents;string"]=""
  )
  declare -a XOR=( "source,contents" )
  # populates the dict "options" for us
  local -A options
  std.argparser options "$@" || return 1
  log.debug "argparse successful"
  [[ -e "$_filename" && -f "$_filename" ]] || return 1
  log.debug "file exists and is a file"
  path.has_uid "$_filename" "${options["owner"]}" || return 1
  log.debug "file owner is correct"
  path.has_gid "$_filename" "${options["group"]}" || return 1
  log.debug "file group is correct"
  path.has_mode "$_filename" "${options["mode"]}" || return 1
  log.debug "file mode is correct"
  if [[ -n "${options["contents"]}" ]]; then
    log.debug "testing contents"
    std.file.has_content "$_filename" "${options["contents"]}" || return 1
    
    
  else
    log.debug "testing source"
    std.file.matches "$_filename" "${options["source"]}" || return 1
  fi
  unset OPTIONS
  unset XOR
  return 0
}

std.file.update() {
  local _filename tmpfn
  _filename="$1"
  shift
  log.debug "updating $_filename"
  declare -A OPTIONS=(
    ["s|source;string"]=""
    ["m|mode;mode"]="644"
    ["o|owner;string"]="root"
    ["g|group;string"]="root"
    ["c|contents;string"]=""
  )
  declare -a XOR=( "source,contents" )
  log.debug "attempting argparse"
  local -A options
  std.argparser options "$@" || return 1
  log.debug "argparse successful"
  
  tmpfn=$(mktemp "$_filename".XXXXXXXXXX)
  
  if [[ -n "${options["source"]}" ]]; then
    log.debug "updating file by source"
    /usr/bin/cp "${options["source"]}" "$tmpfn"
  elif [[ -n "${options["contents"]}" ]]; then
    log.debug "updating file by tee"
    # Do it quietly
    /bin/echo "${options["contents"]}" | /usr/bin/tee "$tmpfn" > /dev/null
  else
    # Fail
    log.debug "neither source nor options set?"
    return 1;
  fi
  /bin/chmod "${options["mode"]}"  "$tmpfn" || return 1
  /bin/chown "${options["owner"]}" "$tmpfn" || return 1
  /bin/chgrp "${options["group"]}" "$tmpfn" || return 1
  
  mv -f "$tmpfn" "$_filename"
  
  unset OPTIONS
  unset XOR
  return 0
}