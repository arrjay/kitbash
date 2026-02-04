docker.network.present() {
  local _network=$1; shift
  # TODO:
  # - Support some of the network driver options, which might be necessary,
  #    at some point
  # -

  __babashka_log "== ${FUNCNAME[0]} $_network"
  # this needs to verify that Docker is, in fact, installed
  if ! [[ -e /usr/bin/docker ]] && ! [[ -x /usr/bin/docker ]]; then
    # Error out, because we don't have Docker installed
    __babashka_fail "Docker is not installed"
  fi
  
  function get_id() {
    echo "${_network}"
  }
  function is_met() {
    HASH="$(docker network ls -q -f "name=${_network}" 2>/dev/null)"
    # __babashka_log "found hash ${HASH}"
    if [[ -z "$HASH" ]]; then
      return 1
    fi
    return 0
  }
  function meet() {
    docker network create "${_network}" > /dev/null 2>&1
  }
  process
}

docker.network.absent() {
  local _network
  _network=$1
  shift
  __babashka_log "== ${FUNCNAME[0]} $_network"
  # this needs to verify that Docker is, in fact, installed
  if ! [[ -e /usr/bin/docker ]] && ! [[ -x /usr/bin/docker ]]; then
    # Error out, because we don't have Docker installed
    __babashka_fail "Docker is not installed"
  fi

  function is_met() {
    HASH="$(docker network ls -q -f "name=${_network}")"
    if [[ -z "$HASH" ]]; then
      return 1
    fi
    return 0
  }
  function meet() {
    docker network rm "${_network}" > /dev/null 2>&1
  }
  process
}
