function __system.debian.repo.custom.worker() {
  system.file ${_gpg_key_path} \
    -o root \
    -g root \
    -m 0644 \
    -s ${_keyfile}
  # I'm not sure this is a good idea...
  # The signed-by, specifically
  system.file ${_repo_path} \
    -o root \
    -g root \
    -m 0644 \
    -c "$_contents"
}

function system.debian.repo.custom() {
  local _repo_name=$1; shift

  while getopts "k:u:a:c:d:" opt; do
    case "$opt" in
      k)
        # Key URL or file
        local key=$(echo $OPTARG | xargs);;
      u)
        # URL of the repo
        local url=$(echo $OPTARG | xargs);;
      a)
        # arch
        local arch=$(echo $OPTARG | xargs);;
      c)
        local channel=$(echo $OPTARG | xargs);;
      d)
        # override the distribution name
        local distribution=$(echo $OPTARG | xargs);;
    esac
  done
  # Reset our loops, to not break other things
  unset OPTIND
  unset OPTARG
  __funcname="${FUNCNAME[0]}"
  # emit apply "$__funcname $_repo_name"
  local _gpg_key_path=/usr/share/keyrings/"${_repo_name}"-archive-keyring.gpg
  local _repo_path=/etc/apt/sources.list.d/"${_repo_name}".list
  
  if [[ -z "$distribution" ]]; then
    distribution=$(/usr/bin/lsb_release -cs)
  fi
  if [[ -z "$arch" ]]; then
    arch=$(/usr/bin/dpkg --print-architecture)
  fi
  
  
  # If the key is an http link, fetch it first
  
  local _keyfile
  if echo "$key" | grep -q "http[s]*://"; then
    log.info "${__funcname}: Fetching remote GPG key"
    
    /usr/bin/curl -fsSL "$key" | $__babashka_sudo /usr/bin/gpg --dearmor --yes -o "${HOME}/${_repo_name}"-archive-keyring.gpg
    _keyfile="$HOME/${_repo_name}"-archive-keyring.gpg
  else
    _keyfile="$key"
  fi
  
  # Generate what we expect the contents to look like
  # This does not support deb822 format as that is not commonly available at
  #   time of writing (8 Jun 2025)
  _contents="deb [arch=${arch} signed-by=${_gpg_key_path}] ${url} ${distribution} ${channel}"
    
  function get_id() {
    echo "${_repo_name}"
  }
  
  function is_met() {
    # and the apt repo on-disk is up-to-date? Hmm.
    
    log.debug "key path: $_gpg_key_path"
    log.debug "repo path: $_repo_path"
    
    std.file.check "$_repo_path" \
      contents "$_contents" \
    || return 1
    
    std.file.check "$_gpg_key_path" \
      source "$_keyfile" \
    || return 1
    
  }
  function meet() {
    emit apply "updating $_gpg_key_path"
    std.file.update "$_gpg_key_path" \
      source "$_keyfile" \
    || return 1
    
    emit apply updating "$_repo_path"
    std.file.update "$_repo_path" \
      contents "$_contents" \
    || return 1
      
    # requires_nested __system.debian.repo.custom.worker || return 1

    emit info "running apt update"
    DEBIAN_FRONTEND=noninteractive /usr/bin/apt-get -yqq update
    return 0
  }
  process
}