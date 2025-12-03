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

kitbash.model() {
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
      log.debug "$keyname: $val"
      echo "$val"
    done
  else
    echo "${KITBASH_MODELS["${model}__${keyname}"]}"
  fi
}

kitbash.model.variables() {
  local val
  log.debug "$1"
  for val in $(kitbash.model "$1" variables); do
    echo "$val"
  done
}

kitbash.model.inherits() {
  local model
  model="$1"
  log.debug "$model"
  local val
  for val in $(kitbash.model "$1" inherits); do
    echo "$val"
  done
}

kitbash.model.kits() {
  log.debug "$1"
  local val
  for val in $(kitbash.model "$1" kits); do
    echo "$val"
  done
}

kitbash.model.secrets() {
  log.debug "$1"
  local val
  for val in $(kitbash.model "$1" secrets); do
    echo "$val"
  done
}