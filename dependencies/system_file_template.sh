# A templated file
# Expects/needs a template renderer of some variety


system.file.template() {
  # path to manage
  local _file_name=$1; shift

  # g: gid or group name
  # o: uid or username
  # t: template
  
  # Declare the array that'll hold our values
  # local _vararray=()
  local -a sources
  local -a vararray
  while getopts "g:o:m:t:s:" opt; do
    case "$opt" in
      g)
        local _group=$(echo $OPTARG | xargs);;
      o)
        local _owner=$(echo $OPTARG | xargs);;
      m)
        local _mode=$(echo $OPTARG | xargs);;
      t)
        local _template=$(echo $OPTARG | xargs);;
      s)
        # Set a variables file
        # ... why is this -s and not -v ?
        #     TODO: Allow it to fall through?
        # Allows for multiple variable files to be used
        
        vararray+=( $OPTARG );;
    esac
  done
  unset OPTIND
  unset OPTARG
  __babashka_log "== ${FUNCNAME[0]} $_file_name"
  # Ughhhhh this is wrong
  # Do I need a config file for this?
  if ! [[ -e /usr/bin/mo ]]; then
    __babashka_fail "${FUNCNAME[0]}: template renderer mo not installed."
  fi
  if [[ -z "$_template" ]]; then
    __babashka_fail "${FUNCNAME[0]}: template path must be set with -t."
  fi
  if ! [[ -e "$_template" ]]; then
    __babashka_fail "${FUNCNAME[0]}: template $_template does not exist."
    exit -1
  fi
  
  local _variables=""
  for var in "${vararray[@]}"; do 
    if ! [[ -e "$var" ]]; then
      __babashka_fail "${FUNCNAME[0]}: variable source file $var does not exist."
    fi
    sources+=("-s=$var")
  done
  
  # Find all the Mo helpers so we can inject them as sources
  # Assumes, based on using the default installer, that any helpers
  #   will be in /etc/babashka/helpers/mo.
  # TODO: Make this configurable?
  local helper
  
  local pth dir
  for pth in "${KITBASH_LIBRARY_PATHS[@]}"; do
    dir="$pth/mo"
    if [[ -e "$dir" && -d "$dir" ]]; then
      for helper in $(find "$dir" -name "*.sh"); do
        # __helpers="-s=${__helper} ${__helpers}"
        sources+=("-s=$helper")
      done
    fi
  done
  
  get_id() {
    echo "${_file_name}"
  }
  
  mo_cmd="/usr/bin/mo -u -x --fail-on-file --allow-function-arguments ${sources[@]} $_template"
  # Strip all unnecessary whitespace
  mo_cmd=$(normalize "$mo_cmd")
  local contents
  contents="$("$mo_cmd")"
  
  is_met() {
    # Basic existence and mode settings
    std.file.check "$_file_name" \
      contents "$contents" \
      group "${_group:-root}" \
      owner "${_owner:-root}" \
      mode "${_mode:-644}" || return 1

  }
  meet() {
    
    std.file.update "$_file_name" \
      contents "$contents" \
      group "${_group:-root}" \
      owner "${_owner:-root}" \
      mode "${_mode:-644}" || return 1
      
  }
  process "${FUNCNAME[0]}" "$_file_name"
}
