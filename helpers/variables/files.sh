# Variables file loader

# Files should probably be the last element
kitbash.vars.register_resolver kitbash.vars.from_files append

# kitbash.vars.from_files
# Usage: kitbash.vars.from_files NAME
# Reloads all the variables files in __KITBASH_VARIABLES_PATH in ascending
# lexical order into the private hash __KITBASH_VAR_CACHE.
# Takes NAME to provide an interface for 
kitbash.vars.from_files() {
  local name="$1"
  local fn line key val directory
  log.debug "Searching for variable: '$name'"
  # Does not currently recurse
  # TODO: Add recursion?
  for directory in "${KITBASH_VARIABLE_PATHS[@]}"; do
    if ! [[ -d "$directory" ]]; then
      log.debug "Missing variable directory: '$directory'"
      continue
    fi
    # "$directory"/*
    for fn in $(find  -L "$directory" -maxdepth 1 -type f | sort -nr); do
      log.debug "Checking file: '$fn'"
      if ! [[ -f "$fn" ]]; then
        log.debug "Not a file..."
        continue
      fi
      
      if ! [[ "$fn" == *.sh ]]; then
        log.warn "$fn is not suffixed with .sh!"
        continue
      fi
      # || -n $line catches the edge case of the final line not having a newline
      # which would cause read to skip the last line
      while IFS= read -r line || [[ -n "$line" ]]; do
        # We don't need comments
        line="${line%%#*}"
        # Use the built-in text normalizer to strip leading and trailing line
        # whitespace
        line=$(normalize "$line")
        # Is the line empty?
        [[ -z "$line" ]] && continue
    
        # Match KEY=value
        if [[ "$line" =~ ^([A-Za-z_][A-Za-z0-9_]*)=(.*)$ ]]; then
          key="${BASH_REMATCH[1]}"
          val="${BASH_REMATCH[2]}"
          log.debug "Adding to cache: '$key'='$val"
          __KITBASH_VAR_CACHE["$key"]="$val"
        fi
      done < "$fn"
    done
  done
  if [[ -v __KITBASH_VAR_CACHE["$key"] ]]; then
    printf "%s" "${__KITBASH_VAR_CACHE["$key"]}"
  fi
}