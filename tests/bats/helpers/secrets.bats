DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )"
load "../../bats_helpers/bats-support/load"
load "../../bats_helpers/bats-assert/load"
# load "../../helpers/system_info.sh"

setup() {
  DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )"
  
  # Load Babashka itself
  . "${DIR}/../../../bin/babashka"
  # load the bats helpers
  . "${DIR}/../../../helpers/00-color.sh"
  . "${DIR}/../../../helpers/00-log.sh"
  . "${DIR}/../../../helpers/01-core.sh"
  . "${DIR}/../../../helpers/02-system_info.sh"
  . "${DIR}/../../../helpers/variables.sh"
  export KITBASH_TEST_CALLER="$BATS_TEST_FILENAME"
}

teardown() {
  unset KITBASH_SECRET_PATHS
  unset KITBASH_CURRENT_MODEL
  unset KITBASH_MODEL_INHERITANCE
}

@test "info.var.secret returns present secret" {
  # KITBASH_LOG_LEVEL=0
  KITBASH_SECRET_PATHS=("$DIR/variables/basic")
  run info.var.secret "GREETING"
  assert_output "hello"
}

@test "info.var.secret fails on missing" {
  KITBASH_SECRET_PATHS=("$DIR/variables/basic")
  run info.var.secret "MISSING"
  assert_failure 1
}

@test "info.var.secret model script file overrides" {
  # KITBASH_LOG_LEVEL=0
  KITBASH_SECRET_PATHS=("$DIR/variables/basic" "$DIR/variables/with_model_script")
  KITBASH_MODEL_INHERITANCE=(modelname)
  KITBASH_CURRENT_MODEL=modelname
  run info.var.secret "GREETING"
  assert_output "modelname"
}