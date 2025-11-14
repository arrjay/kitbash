DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )"
load "../../bats_helpers/bats-support/load"
load "../../bats_helpers/bats-assert/load"
# load "../../helpers/system_info.sh"

setup() {
  DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )"
  
  # Load Babashka itself
  # . "${DIR}/../../../bin/babashka"
  # load the bats helpers
  . "${DIR}/../../../helpers/00-color.sh"
  . "${DIR}/../../../helpers/00-log.sh"
  . "${DIR}/../../../helpers/01-core.sh"
  export KITBASH_TEST_CALLER="$BATS_TEST_FILENAME"
}

teardown() {
  unset KITBASH_TEST_CALLER
  unset TEST_VARIABLE
}

@test "kitbash.path: returns current working path" {
  run kitbash.path
  assert_output "$DIR"
}