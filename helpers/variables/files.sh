# Variables file loader

# Load from general variables files
kitbash.vars.register_resolver kitbash.vars.files.general append
# Load from secrets variables files
kitbash.vars.secrets.register_resolver kitbash.vars.files.secret

# declare -ag __KITBASH_CHECKED_FILES
declare -g __KITBASH_LOAD_FILES
__KITBASH_LOAD_FILES=1

# kitbash.vars.files.general
# Usage: kitbash.vars.files.general NAME
# Reloads all the variables files in __KITBASH_VARIABLES_PATH in ascending
# lexical order into the private hash __KITBASH_VAR_CACHE.
# Takes NAME to provide an interface for info.var lookup
kitbash.vars.files.general() {
  local name
  name="$1"
  local fn line key val directory
  log.debug "Searching for variable: '$name'"
  # Does not currently recurse
  # TODO: Add recursion?
  
  # Only try to load the files on the first go, no point wasting cycles doing
  # it again
  log.debug "Files loader attempting to load files: '$__KITBASH_LOAD_FILES'"
  if [[ "$__KITBASH_LOAD_FILES" == 1 ]]; then
  # Uses a nameref to the variable paths array
    for fn in $(kitbash.vars.files.list KITBASH_VARIABLE_PATHS); do
      log.debug "Checking file '$fn'"
      for line in $(kitbash.vars.files.read "$fn"); do
        kitbash.vars.files.cache "$line"
      done
    done
    __KITBASH_LOAD_FILES=0
  fi
  
  if [[ -v __KITBASH_VAR_CACHE["$name"] ]]; then
    echo "${__KITBASH_VAR_CACHE["$name"]}"
    return
  fi
  return 1
}

kitbash.vars.files.list() {
  local -n paths
  paths="$1"
  local model directory models_d fn suffix
  local -a search_paths
  for directory in "${paths[@]}"; do
    models_d="$directory"/"$KITBASH_MODELS_DIRECTORY_NAME"
    log.debug "Using models directory $models_d"
    
    # The first model loaded is the model we're examining, always.
    # Then it proceeds down the tree to subsequent models, to see if they have
    # defined any variable files, to allow for models to provide a default
    # definition for any given variable.
    for model in "${__KITBASH_MODEL_TREE_STACK[@]}"; do
      model_path="$models_d/$KITBASH_CURRENT_MODEL"
      # If a current model is defined, we want to scope our variable lookups
      # to that.
      # That means we'll either load up a file with the model's name AND/OR
      # all the files in the directory with the model's name.
      
      if [[ -e "$model_path" && -d "$model_path" ]]; then
        search_paths+=("$model_path")
      fi
      # Now, look in the models.d directory for any files named for the model
      # we're looking at.
      for suffix in "${KITBASH_VARIABLE_SUFFIXES[@]}"; do
        log.debug "Checking for suffixed model files matching '$model'"
        fn="$models_d"/"$model"."$suffix"
        log.debug "Checking '$fn'"
        if [[ -e "$fn" ]]; then
          log.debug "found model file: '$fn'"
          echo "$fn"
        fi
      done
    done
  done
  # Recombine discovered search paths with original incoming paths
  search_paths=("${search_paths[@]}" "${paths[@]}")
  unset directory
  for directory in "${search_paths[@]}"; do
    log.debug "Searching path $directory"
    kitbash.vars.files.list_directory "$directory"
  done
}

# kitbash.vars.files.secret
# Returns a secret based on the provided key
# Does not cache. Parses all secrets files on each invocation.
# This is intentional, to allow for (for example) a FIFO buffer connected to
# a logging script to log when secrets are read.
kitbash.vars.files.secret() {
  local name
  name="$1"
  local fn line key val directory
  log.debug "Searching for key: '$name'"
  if [[ "${KITBASH_SECRET_PATHS[@]}" == 0 ]]; then
    log.error "No secret paths defined!"
    kitbash.fail
  fi
  for fn in $(kitbash.vars.files.list KITBASH_SECRET_PATHS); do
    log.debug "Searching in '$fn'"
    for line in $(kitbash.vars.files.read "$fn"); do
      # I wish there was a better way to do this.
      if [[ "$line" =~ ^([A-Za-z_][A-Za-z0-9_]*)=(.*)$ ]]; then
        key="${BASH_REMATCH[1]}"
        val="${BASH_REMATCH[2]}"
        if [[ "$key" == "$name" ]]; then
          echo "$val"
          return 0
        fi
      fi
    done
  done
  log.error "No such secret '$name'"
  return 1
}

kitbash.vars.files.cache() {
  local line key val
  line="$1"
  
  line="${line%%#*}"
  # Use the built-in text normalizer to strip leading and trailing line
  # whitespace
  line=$(normalize "$line")
  # Is the line empty?
  [[ -z "$line" ]] && return 1
  # Match KEY=value
  if [[ "$line" =~ ^([A-Za-z_][A-Za-z0-9_]*)=(.*)$ ]]; then
    key="${BASH_REMATCH[1]}"
    val="${BASH_REMATCH[2]}"
    log.debug "Found key: $key"
    # Only load into cache if it's not already been found.
    # If it has, we can ignore it.
    if ! [[ -v __KITBASH_VAR_CACHE["$key"] ]]; then
      log.debug "Adding to cache: '$key'='$val"
      __KITBASH_VAR_CACHE["$key"]="$val"
    fi
  fi
}

kitbash.vars.files.read() {
  local fn
  fn="$1"
  [[ -e "$fn" && -f "$fn" ]] || {
    log.warn "Not a file: '$fn'"
    return 1
  }
  while IFS='\n' read -r line || [[ -n "$line" ]]; do
    # We don't need comments
    log.debug "Loaded initial line: '$line'"
    line="${line%%#*}"
    # Use the built-in text normalizer to strip leading and trailing line
    # whitespace
    line=$(normalize "$line")
    # Is the line empty?
    [[ -z "$line" ]] && continue
  
    # Match KEY=value
    if [[ "$line" =~ ^([A-Za-z_][A-Za-z0-9_]*)=(.*)$ ]]; then
      printf '%s\n' "$line"
    else
      log.error "Bad line in $fn: $line"
    fi
  done < "$fn"
}

kitbash.vars.files.load_directory() {
  local fn directory
  directory="$1"
  if ! [[ -e "$directory" && -d "$directory" ]]; then
    log.warn "No such directory: '$directory'"
    return 0
  fi
  # Uses reverse order so that files can be dropped in via orchestrator or
  # other system with large prefixes and get selected first.
  for fn in $(find  -L "$directory" -maxdepth 1 -type f | sort -nr); do
    log.debug "Checking file: '$fn'"
    # If the filename suffix is in our global kitbash variable name suffixes,
    # then we attempt to read it.
    if types.array.contains KITBASH_VARIABLE_SUFFIXES "${fn##*.}"; then
      log.debug "File suffix matches allowed suffixes"
      kitbash.vars.files.read "$fn"
    fi
  done
}

kitbash.vars.files.list_directory() {
  local fn directory
  directory="$1"
  log.debug "Searching $directory..."
  if ! [[ -e "$directory" && -d "$directory" ]]; then
    log.debug "No such directory: '$directory'"
    return 0
  fi
  # Uses reverse order so that files can be dropped in via orchestrator or
  # other system with large prefixes and get selected first.
  log.debug "Finding files"
  for fn in $(find -L "$directory" -maxdepth 1 -type f | sort -nr); do
    log.debug "Checking file: '$fn'"
    # If the filename suffix is in our global kitbash variable name suffixes,
    # then we attempt to read it.
    if types.array.contains KITBASH_VARIABLE_SUFFIXES "${fn##*.}"; then
      log.debug "File suffix matches allowed suffixes"
      echo "$fn"
    fi
  done
}