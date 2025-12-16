# Variables resolver

# Provides an interface for querying defined variables, without kits or
# implementations trying to source in files at random from
# `/etc/kitbash/variables`.
# Designed for pluggability of resolvers, so that new resolvers can be added
# without much issue later on.

declare -ag __KITBASH_VAR_RESOLVERS
declare -ag __KITBASH_VAR_SECRET_RESOLVERS

declare -ag __KITBASH_VAR_RESOLVERS_INIT

declare -Ag __KITBASH_VAR_CACHE
declare -g __KITBASH_LOAD_VARIABLES
__KITBASH_LOAD_VARIABLES=0

# info.var
# Usage: info.var NAME [DEFAULT]
# Lookup precedence:
#   1. Cached value (if already loaded)
#   2. Resolvers as defined in __KITBASH_VAR_RESOLVERS
info.var() {
  local name default value
  name="$1"
  default="${2-}"
  value=""
   
  [[ "$name" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || {
    log.error "Invalid variable name: %s" "$name"
    return 1
  }
  
  # This is still wrong.
  # TODO: Fix this, since it'll cause weirdness later on with variable providers that aren't "load everything" style.
  
  log.debug "Searching for variable: '$name'"
  if (( __KITBASH_LOAD_VARIABLES == 0 )); then
    log.debug "kitbash loading variables..."
    value=$(kitbash.vars.load "$name")
    [[ -n "$value" ]] && {
      echo "$value"
      __KITBASH_LOAD_VARIABLES=1
      return 0
    }
  fi

  # 1. Cached value
  if [[ -n "${__KITBASH_VAR_CACHE["$name"]+x}" ]]; then
    log.debug "info.var: cache hit for '$name'"
    log.debug "Value: ${__KITBASH_VAR_CACHE["$name"]}"
    echo "${__KITBASH_VAR_CACHE["$name"]}"
    return 0
  fi
  # 3. Default / error
  if [[ -n "$default" ]]; then
    log.debug "info.var: returning default for '$name'"
    echo "$default"
    return 0
  fi

  log.error "Variable '$name' not set and no default provided"
  return 1
}

info.var.secret() {
  local name resolver val
  name="$1"
  log.debug "Searching for secret '$name'"
  [[ "$name" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || {
    log.error "Invalid variable name: %s" "$name"
    return 1
  }
  for resolver in "${__KITBASH_VAR_SECRET_RESOLVERS[@]}"; do
    log.debug "Checking resolver '$resolver'"
    val=$("$resolver" "$name")
    if [[ -n "$val" ]]; then
      echo "$val"
      return 0
    fi
  done
  return 1
}

# kitbash.vars.reload
# Usage: kitbash.vars.reload
# Used to tell the variable loader that it needs to re-parse the variable
# providers and update the internal cache.
kitbash.vars.reload() {
  __KITBASH_LOAD_VARIABLES=0
}

# kitbash.vars.load
# Usage: kitbash.vars.load NAME
# Attempts to load the variable into cache, in reverse order of declaration in
# __KITBASH_VAR_RESOLVERS, with the last resolver winning.
# Default resolver loads files in /etc/kitbash/variables in ascending lexical
# order.
kitbash.vars.load() {
  # 2. Run through resolvers in order
  local resolver
  local name
  name="$1"
  
  log.debug "Attempting to load variable: '${name}'"
  log.debug "Resolvers: ${__KITBASH_VAR_RESOLVERS[@]}"
  for resolver in "${__KITBASH_VAR_RESOLVERS[@]}"; do
    log.debug "Using resolver: '${resolver}'"
    if declare -F "$resolver" > /dev/null 2>&1; then
      log.debug "'$resolver' is a defined function."
      value="$("$resolver" "$name")" || true
      if [[ -n "$value" ]]; then
        log.debug "info.var: resolved '$name' via $resolver"
        __KITBASH_VAR_CACHE["$name"]="$value"
        printf '%s' "$value"
        return 0
      fi
    else
      log.debug "info.var: skipping undefined resolver $resolver"
    fi
  done
  __KITBASH_LOAD_VARIABLES=1
}

kitbash.vars.register_resolver() {
  local function
  function="$1"
  log.debug "Registering resolver: '${function}'"
  local mode
  mode="${2:-prepend}"
  
  case "$mode" in
    prepend)
      log.debug "Prepending '${function}'"
      types.set.prepend __KITBASH_VAR_RESOLVERS "$function"
      ;;
    append|*)
      log.debug "Appending '${function}'"
      types.set.append __KITBASH_VAR_RESOLVERS "$function"
      ;;
  esac
  log.debug "Resolvers now contains: '${__KITBASH_VAR_RESOLVERS[@]}'"
}

kitbash.vars.secrets.register_resolver() {
  local function
  function="$1"
  log.debug "Registering secrets resolver: '${function}'"
  local mode
  mode="${2:-prepend}"
  
  case "$mode" in
    prepend)
      log.debug "Prepending '${function}'"
      types.set.prepend __KITBASH_VAR_SECRET_RESOLVERS "$function"
      ;;
    append|*)
      log.debug "Appending '${function}'"
      types.set.append __KITBASH_VAR_SECRET_RESOLVERS "$function"
      ;;
  esac
  log.debug "Resolvers now contains: '${__KITBASH_VAR_SECRET_RESOLVERS[@]}'"
}


# External interface for exporting variables
kitbash.export() {
  eval "$(kitbash.__export "$@")"
}

# Internal function
# Generates a list of printf statements to create local -x scoped variables,
# so that `mo` can source variables from the environment as expected during
# its run.
kitbash.__export() {
  local name value
  for name in "$@"; do
    value="$(info::var "$name")" || return 1
    printf 'local -x %s=%q\n' "$name" "$value"
  done
}

kitbash.vars.init.register() {
  local function
  function="$1"
  log.debug "Registering init: '${function}'"
  local mode
  mode="${2:-prepend}"
  case "$mode" in
    prepend)
      log.debug "Prepending '${function}'"
      types.set.prepend __KITBASH_VAR_RESOLVERS_INIT "$function"
      ;;
    append|*)
      log.debug "Appending '${function}'"
      types.set.append __KITBASH_VAR_RESOLVERS_INIT "$function"
      ;;
  esac
}

kitbash.vars.init() {
  local init
  for init in "${__KITBASH_VAR_RESOLVERS_INIT[@]}"; do
    log.debug "Calling $init"
    "$init"
  done
}

kitbash.load variables/files.sh
