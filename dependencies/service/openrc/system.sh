system.service.enable.openrc() {
  local _unit
  _unit=$1
  shift
  
  emit info "$_unit"
  
  while getopts "l:" opt; do
    case "$opt" in
      # echoing through xargs trims whitespace
      l)
        _runlevel=$(echo $OPTARG | xargs);;
    esac
  done
  # Reset the option parsing
  unset OPTIND
  unset OPTARG
  
  if ! [ -e /etc/init.d/$_unit ]; then
    kitbash.fail "No service $_unit"
  fi
  
  if [[ "$_runlevel " == " " ]]; then
    _runlevel="default"
  fi
  
  function get_id() {
    echo "${_unit}"
  }
  function is_met() {
    emit info "Checking status"
    rc-update show | grep "$_unit" | grep -q "$_runlevel"
  }
  function meet() {
    emit info "Adding $_unit to $_runlevel"
    rc-update add "$_unit" "$_runlevel"
  }
  process
}

system.service.disable.openrc() {
  local _service
  _service=$1
  shift
  
  emit info "$_service"
  
  while getopts "l:" opt; do
    case "$opt" in
      # echoing through xargs trims whitespace
      l)
        _runlevel=$(echo $OPTARG | xargs);;
    esac
  done
  # Reset the option parsing
  unset OPTIND
  unset OPTARG
  
  if ! [[ -e /etc/init.d/"$_service" ]]; then
    __babashka_fail "${FUNCNAME[0]} (openrc) No service $_unit."
  fi
  
  if [[ -z "$_runlevel" ]]; then
    _runlevel="default"
  fi
  
  function get_id() {
    echo "${_service}"
  }
  
  function is_met() {
    ! rc-update show | grep "$_service" | grep -q "$_runlevel"
  }
  function meet() {
    rc-update delete "$_service"
  }
  process
}

system.service.started.openrc() {
  local _service=$1; shift
  __babashka_log "== ${FUNCNAME[0]} (openrc) $_service"
  
  if ! [[ -e /etc/init.d/"$_service" ]]; then
    __babashka_fail "${FUNCNAME[0]} (openrc) No service $_unit."
  fi
  
  function get_id() {
    echo "${_service}"
  }
  function is_met() {
    rc-service "$_service" status | grep -q "status: started"
  }
  function meet() {
    rc-service "$_service" start > /dev/null
  }
  process
}

system.service.stopped.openrc() {
  local _service=$1; shift
  __babashka_log "== ${FUNCNAME[0]} (openrc) $_service"
  
  if ! [ -e /etc/init.d/$_service ]; then
    __babashka_fail "${FUNCNAME[0]} (openrc) No service $_unit."
  fi
  
  function get_id() {
    echo "${_service}"
  }
  
  function is_met() {
    rc-service $_service status | grep -q "status: stopped"
  }
  function meet() {
    $__babashka_sudo rc-service $_service stop > /dev/null
  }
  process
}

system.service.reload.openrc() {
  local _service;
  _service="$1"
  shift
  emit "$_service"
  local has_met
  has_met=1
  is_met() {
    rc-service "$_service" status | grep -q "status: started" || {
      kitbash.fail "Service $_not running"
    }
    return "$has_met"
  }
  meet() {
    rc-service reload "$_service" || {
      kitbash.fail "Service $_service could not be reloaded"
    }
    has_met=0
  }
  process
}

system.service.restart.openrc() {
  local _service;
  _service="$1"
  shift
  emit "$_service"
  local has_met
  has_met=1
  is_met() {
    rc-service "$_service" status | grep -q "status: started" || {
      kitbash.fail "Service $_not running"
    }
    return "$has_met"
  }
  meet() {
    rc-service restart "$_service" || {
      kitbash.fail "Service $_service could not be reloaded"
    }
    has_met=0
  }
  process
}

system.info.init openrc || return

system.service.enable() {
  system.service.enable.openrc "$@"
}
system.service.disable() {
  system.service.disable.openrc "$@"
}
system.service.started() {
  system.service.started.openrc "$@"
}
system.service.stopped() {
  system.service.stopped.openrc "$@"
}
system.service.reload() {
  system.service.reload.openrc "$@"
}
system.service.reload() {
  system.service.restart.openrc "$@"
}