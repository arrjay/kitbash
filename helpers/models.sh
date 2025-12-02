declare -Ag KITBASH_MODEL_STRUCTURE
# TODO
# Make version use semver
KITBASH_MODEL_STRUCTURE=(
  [name]="string;required"
  [description]="string;optional"
  [version]="string;required"
  [inherits]="array;optional"
  [entrypoint]="string;optional"
  [variables]="array;optional"
  [kits]="array;optional"
  [secrets]="array;optional"
)

kitbash.model.has_key() {
  [[ -v KITBASH_MODELS["${1}__${2}"] ]]
}

kitbash.model.key() {
  local model keyname keys ary keytype keyopt vals
  
  # Grab all the keys out
  ary=("${!KITBASH_MODEL_STRUCTURE[@]}")
  model="$1"
  keyname="$2"
  if ! contains ary "$keyname"; then
    log.error "Invalid key: $keyname"
    return 1
  fi
  log.debug "$model: $keyname"
  if ! [[ -v KITBASH_MODELS["${model}__${keyname}"] ]]; then
    log.debug "$model: no $keyname" 
    return
  fi
  IFS=";" read -ra keytype keyopt <<< "${KITBASH_MODEL_STRUCTURE["${keyname}"]}"
  log.debug "$keytype $keyopt"
  if [[ "$keytype" == "array" ]]; then
    IFS="," read -ra vals <<< "${KITBASH_MODELS["${model}__${keyname}"]}"
    log.debug "$model: ${#vals[@]}"
    for val in "${vals[@]}"; do
      log.debug "model: $val"
      echo "$val"
    done
  else
    echo "${KITBASH_MODELS["${model}__${keyname}"]}"
  fi
}

kitbash.model.variables() {
  local model
  model="$1"
  log.debug "$model"
  kitbash.model.key "$model" variables
}

kitbash.model.inherits() {
  local model
  model="$1"
  log.debug "$model"
  kitbash.model.key "$model" inherits
}

kitbash.model.kits() {
  log.debug "$1"
  kitbash.model.key "$1" kits
}

kitbash.model.secrets() {
  log.debug "$1"
  kitbash.model.key "$1" secrets
}