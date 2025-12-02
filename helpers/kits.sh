declare -Ag KITBASH_KIT_STRUCTURE
# TODO
# Make version use semver
KITBASH_KIT_STRUCTURE=(
  [name]="string;required"
  [description]="string;optional"
  [version]="string;required"
  [depends]="array;optional"
  [entrypoint]="string;optional"
  [variables]="array;optional"
  [secrets]="array;optional"
)

kitbash.kit.has_key() {
  [[ -v KITBASH_KITS["${1}__${2}"] ]]
}

kitbash.kit.key() {  
  local model keyname keys ary keytype keyopt vals
  
  # Grab all the keys out
  ary=("${!KITBASH_KIT_STRUCTURE[@]}")
  kit="$1"
  keyname="$2"
  if ! contains ary "$keyname"; then
    log.error "Invalid key: $keyname"
    return 1
  fi
  log.debug "$kit: $keyname"
  if ! [[ -v KITBASH_KITS["${kit}__${keyname}"] ]]; then
    log.debug "$kit: no $keyname" 
    return
  fi
  IFS=";" read -ra keytype keyopt <<< "${KITBASH_KIT_STRUCTURE["${keyname}"]}"
  
  if [[ "$keytype" == "array" ]]; then
    IFS="," read -ra vals <<< "${KITBASH_KITS["${kit}__${keyname}"]}"
    log.debug "$kit: ${#vals[@]}"
    for val in "${vals[@]}"; do
      log.debug "kit: $val"
      echo "$val"
    done
  else
    echo "${KITBASH_MODELS["${kit}__${keyname}"]}"
  fi
}

kitbash.kit.variables() {
  log.debug "$1"
  kitbash.kit.key "$1" variables
}

kitbash.kit.depends() {
  log.debug "$1"
  kitbash.kit.key "$1" inherits
}
kitbash.kit.secrets() {
  log.debug "$1"
  kitbash.kit.key "$1" secrets
}