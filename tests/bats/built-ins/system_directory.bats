load "../../bats_helpers/bats-support/load"
load "../../bats_helpers/bats-assert/load"

setup_file() {
  DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )"
  # load Kitbash, so we get `process`
  . "${DIR}/../../../bin/babashka"
  # load the babashka core functions
  . "${DIR}/../../../helpers/00-log.sh"
  . "${DIR}/../../../helpers/01-core.sh"
  . "${DIR}/../../../helpers/02-system_info.sh"
  . "${DIR}/../../../helpers/03-system.sh"
  . "${DIR}/../../../helpers/argparser.sh"
  . "${DIR}/../../../helpers/typechecker.sh"
  . "${DIR}/../../../dependencies/system_directory.sh"
}

setup() {
  DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )"
  . "${DIR}/../../../bin/babashka"
  # load the babashka core functions
  . "${DIR}/../../../helpers/00-color.sh"
  . "${DIR}/../../../helpers/00-log.sh"
  . "${DIR}/../../../helpers/01-core.sh"
  . "${DIR}/../../../helpers/02-system_info.sh"
  . "${DIR}/../../../helpers/03-system.sh"
  . "${DIR}/../../../helpers/argparser.sh"
  . "${DIR}/../../../helpers/typechecker.sh"
  . "${DIR}/../../../dependencies/system_directory.sh"
}

teardown() {
  [[ -e "${DIR}/test_folder" ]] && rm -rf "${DIR}/test_folder"
}

@test "system.directory creates directory" {
  local current_user
  local -a groups
  current_user="$(whoami)"
  IFS=" " read -ra groups < <(groups)
  
  system.directory "${DIR}/test_folder" -o "$current_user" -g "${groups[0]}"
  
  assert [ -e "$DIR/test_folder" ]
}