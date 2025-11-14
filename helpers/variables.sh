# Variables resolver

# Provides an interface for querying defined variables, without kits or
# implementations trying to source in files at random from
# `/etc/kitbash/variables`.
# Designed for pluggability of resolvers, so that new resolvers can be added
# without much issue later on.

declare -ag __KITBASH_VAR_RESOLVERS

declare -Ag __KITBASH_VAR_CACHE
declare __KITBASH_LOAD_VARIABLES
__KITBASH_LOAD_VARIABLES=0

# info.var
# Usage: info.var NAME [DEFAULT]
# Lookup precedence:
#   1. Cached value (if already loaded)
#   2. Resolvers as defined in __KITBASH_VAR_RESOLVERS
info.var() {
  local name="$1"
  local default="${2-}"
  local value=""
  
  log.debug "Searching for variable: '$name'"
  if [[ "${__KITBASH_LOAD_VARIABLES}" -eq 0 ]]; then
    log.debug "kitbash loading variables..."
    kitbash.vars.load "$name"
  fi

  # 1. Cached value
  if [[ -n "${__KITBASH_VAR_CACHE[$name]+x}" ]]; then
    log.debug "info.var: cache hit for '$name'"
    log.debug "Value: ${__KITBASH_VAR_CACHE["$name"]}"
    echo "${__KITBASH_VAR_CACHE["$name"]}"
    return 0
  fi
  # 3. Default / error
  if [[ -n "$default" ]]; then
    log.debug "info.var: using default for '$name'"
    __KITBASH_VAR_CACHE["$name"]="$default"
    echo "$default"
    return 0
  fi

  log.error "Variable '$name' not set and no default provided"
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
    if declare -F "$resolver" >/dev/null 2>&1; then
      log.debug "'$resolver' is a defined function."
      value="$("$resolver" "$name")" || true
      if [[ -n "$value" ]]; then
        log.debug "info.var: resolved '$name' via $resolver"
        __KITBASH_VAR_CACHE["$name"]="$value"
        echo "$value"
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

kitbash.load variables/files.sh