# shellcheck shell=bash
# Manages a file on disk somewhere

function system::file() {
  _file_name="${1}" ; shift
  [[ "${_file_name}" ]] || __kitbash_fail "you must specify a file destination to manage"
  # g: gid or group name
  # u: uid or username
  # s: source (optional)
  # c: contents (optional(?))
  # TODO: Use `getopt` instead to allow more betterer parsing?
  #       Though getopt is often confusing
  #       oh well
  while getopts "g:o:m:s:c:" opt; do
    case "$opt" in
      g)
        group="$(echo $OPTARG | xargs)";;
      o)
        owner="$(echo $OPTARG | xargs)";;
      m)
        mode="$(echo $OPTARG | xargs)";;
      s)
        _source="$(echo $OPTARG | xargs)";;
      c)
        contents="$(echo $OPTARG | xargs)";;
    esac
  done
  unset OPTIND
  unset OPTARG
  kb_log "== ${FUNCNAME[0]} ${_file_name}"

  # setting source *and* contents makes no sense. forbid.
  [[ "${_source}" && "${contents}" ]] && __kitbash_fail "cannot set source and contents for file realization"
  
  function get_id() {
    printf '%s\n' "${_file_name}"
  }

  function get_target() {
    printf 'file:%s\n' "${_file_name}"
  }

  function is_met() {
    # we're only going to check the basics for an existing file.
    # Okay the basic mode stuff is set up properly
    # (though ideally this'd be a helper function instead of C&P from system.directory)
    # TODO I guess?
    [[ -e "${_file_name}" ]] && {
      [[ "${owner}" ]] && { helper::path::owner "${_file_name}" "${owner}" || return 1 ; }
      [[ "${group}" ]] && { helper::path::group "${_file_name}" "${group}" || return 1 ; }
      [[ "${mode}"  ]] && { helper::path::mode  "${_file_name}" "${mode}"  || return 1 ; }
    }

    # the diffs here run through sudo so we're guaranteed to read the file.
    # Okay anyway check contents now if we need to do those.
    [[ "${_source}" ]] && {
      $__kitbash_sudo diff "${_file_name}" "${_source}" || return $?
    }

    # or a contents version...
    [[ "${contents}" ]] && {
      echo "${contents}" | $__kitbash_sudo diff "${_file_name}" - || return $?
    }

    # if we're _here_ all is well.
    return 0
  }

  function meet() {
    [[ "${contents}" ]] && {
      echo "${contents}" | $__kitbash_sudo tee "${_file_name}" > /dev/null
    }

    [[ ${_source} ]] && {
      $__kitbash_sudo cp "${_source}" "${_file_name}"
    }

    [[ "${mode}"  ]] && $__kitbash_sudo chmod "${mode}"  "${_file_name}"
    [[ "${owner}" ]] && $__kitbash_sudo chown "${owner}" "${_file_name}"
    [[ "${group}" ]] && $__kitbash_sudo chgrp "${group}" "${_file_name}"
  }

  process
}

__compat_shim "called legacy system.file" system.file system::file

function system.file.line() {
  local _file=$1; shift
  while getopts "c:" opt; do
    case "$opt" in
      c)
        local _contents="$OPTARG";;
    esac
  done
  unset OPTIND
  unset OPTARG
  __babashka_log "== ${FUNCNAME[0]} $_file $_contents"
  function get_id() {
    echo "${_file}"
  }
  function is_met() {
    # Check the beginning of the line
    $__babashka_sudo grep "^$_contents" $_file
  }
  function meet() {
    echo "$_contents" | $__babashka_sudo tee -a $_file
  }
  process
}

# Ensure a file does not exist
function system.file.absent() {
  local _file=$1; shift;
  __babashka_log "== ${FUNCNAME[0]} $_file"
  if [[ -d $_file ]]; then
    __babashka_fail "ERROR: $_file is a directory"
  fi
  function get_id() {
    echo "${_file}"
  }
  function is_met() {
    ! [[ -e $_file ]];
  }
  function meet() {
    $__babashka_sudo rm $_file;
  }
  process
}
