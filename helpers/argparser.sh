## Implements core argument parsing for Babashka modules.

std.argparser() {
  # Wipe options
  unset options
  # has to declare global in order to return properly
  declare -Ag options
  declare -A normalized
  declare -a is_nullable
  
  log.debug "parsing $@"
  for opt in "${!OPTIONS[@]}"; do
    IFS=";" read -r option type <<< "$opt"
    IFS="|" read -r short long <<< "$option"
    normalized+=(["$option"]="${long:-"$short"}")
  done
  # Loop through all the provided options
  while [[ "$#" -gt 0 ]]; do
    local option_matched=0

    # Check if the argument matches any defined option
    for opt in "${!OPTIONS[@]}"; do
      # Split option definition into name, type, and default
      IFS=";" read -r option type <<< "$opt"
      IFS="|" read -r short long <<< "$option"
      # Match both short and long forms
      if [[ "$1" == "$short" || "$1" == "$long" ]]; then
        # Validate the type of the value
        value="$2"
        # Default type should be string
        if [[ -z "$type" ]]; then
          type="string"
        fi
        if ! std.typecheck "$type" "$value"; then
          log.debug "Invalid value for $option: $value"
          return 1
        fi
        options["${long:-"$short"}"]="$value"
        shift 2
        option_matched=1
        break
      fi
    done
    # If no matching option was found, it's an unknown argument
    if [[ "$option_matched" -eq 0 ]]; then
      log.debug "Unknown argument: $1"
      return 1
    fi
  done
  
  local opt
  local option
  # Apply defaults if no value is provided for any option
  for opt in "${!OPTIONS[@]}"; do
    IFS=";" read -r option type <<< "$opt"
    IFS="|" read -r short long <<< "$option"
    option="${normalized["$option"]}"
    # Only apply default if the option isn't already set
    if ! [[ -v options["$option"] ]]; then
      log.debug "Setting $option to ${OPTIONS[$opt]}"
      options["$option"]="${OPTIONS[$opt]}"
    fi
  done
  
  local xor_group xor_count xor_option
  
  # Check that XOR conditions are met (mutually exclusive options)
  for xor_group in "${XOR[@]}"; do
    IFS=',' read -ra xor_options <<< "$xor_group"
    log.debug "std.argparser: found xor_options ${xor_options[@]}"
    xor_count=0
    # For each option in the group, 
    for xor_option in "${xor_options[@]}"; do
      log.debug "std.argparser: xor checking checking ${xor_option}"
      # Check for each value in the output options hash
      if [[ -n "${options[$xor_option]}" ]]; then
        log.debug "found $xor_option: ${options[$xor_option]}"
        ((xor_count++))
      fi
    done
    # If there's more than one, we can error out
    if [[ $xor_count -gt 1 ]]; then
      log.error "Error: Only one of ${xor_group} can be defined."
      return 1
    fi
    # Otherwise, we throw an error since one needs to be defined
    if [[ $xor_count -eq 0 ]]; then
      log.error "Error: One of ${xor_group} must be defined."
      return 1
    fi
    # Finally, set up our nullable lookup
    for xor_option in "${xor_options[@]}"; do
      if [[ -z "${options[$xor_option]}" ]]; then
          is_nullable+=( "$xor_option" )
      fi
    done
  done
  
  local opt option
  # Check for required options (those with empty string default values)
  for opt in "${!OPTIONS[@]}"; do
    IFS=";" read -r option type <<< "$opt"
    option="${normalized["$option"]}"
    if [[ -z "${options[$option]}" && -z "${OPTIONS[$opt]}" ]]; then
      # If we know we can let this one be nullable, we continue the loop
      in_array "$option" "${is_nullable[@]}" && continue
      # Otherwise, we error out
      log.error "Error: $option is required and cannot be empty."
      return 1
    fi
  done
}