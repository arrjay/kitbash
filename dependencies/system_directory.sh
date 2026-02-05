function system.directory() {
  local directory owner group mode
  directory="$1"
  shift
  
  declare -A OPTIONS=(
    ["-m|--mode;mode"]="0755"
    ["-o|--owner;string"]="root"
    ["-g|--group;string"]="root"
  )
  
  local -A options
  
  std.argparser options "$@" || return 1
  owner="${options["--owner"]}"
  group="${options["--group"]}"
  mode="${options["--mode"]}"
  
  # while getopts "o:g:m:" opt; do
  #   case "$opt" in
  #     o)
  #       local owner=$(echo "$OPTARG" | xargs);;
  #     g)
  #       local group=$(echo "$OPTARG" | xargs);;
  #     m)
  #       local mode=$(echo "$OPTARG" | xargs);;
  #   esac
  # done
  # # Reset the option parsing
  # unset OPTIND
  # unset OPTARG
  __babashka_log "== system.directory $directory"
  # TODO: Support not-Linux?
  function get_id() {
    echo "${directory}"
  }
  function is_met() {
    [[ -e "$directory" && ! -d "$directory" ]] && {
      # There's a file with this name, which is clearly Bad, so we need to abort.
      emit error "$directory is a file!"
      return 1
    }
    
    if ! [[ -e "$directory" && -d "$directory" ]]; then
      emit no "directory does not exist"
      return 1
    fi
    if [[ -n "$group" ]]; then
      path.has_gid "$directory" "$group" || {
        emit no "group is wrong on directory"
        return 1
      }
    fi
    if [[ -n "$owner" ]]; then
      path.has_uid "$directory" "$owner" || {
        emit no "owner is wrong"
        return 1
      }
    fi
    if [[ -n "$mode" ]]; then
      path.has_mode "$directory" "$mode" || {
        emit no "mode is wrong"
        return 1
      }
    fi
    return 0
  }
  function meet() {
    # Create parents automatically
    [[ -e "$directory" && ! -d "$directory" ]] && {
      # There's a file with this name, which is clearly Bad, so we need to abort.
      emit error "$directory is a file!"
      return 1
    }
    if ! [[ -d "$directory" ]]; then
      mkdir -p "$directory" || {
        emit error "Could not create $directory"
        return 1
      }
    fi
    [[ -n "$mode" ]] && chmod "$mode" "$directory" || {
      emit error "could not set mode $mode on directory $directory."
      return 1
    }
    [[ -n "$owner" ]] && chown "$owner" "$directory" || {
      emit error "could not set owner $owner on directory $directory."
      return 1
    }
    [[ -n "$group" ]] && chgrp "$group" "$directory" || {
      emit error "could not set group $group on directory $directory"
      return 1
    }
  }
  process
}

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
