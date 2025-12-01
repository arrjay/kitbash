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
  unset KITBASH_VARIABLE_PATHS
  unset KITBASH_CURRENT_MODEL
  unset __KITBASH_VAR_CACHE
  __KITBASH_LOAD_VARIABLES=0
  unset KITBASH_MODEL_INHERITANCE
}

@test "kitbash.vars.files.general caches basic files" {
  # KITBASH_LOG_LEVEL=0
  KITBASH_VARIABLE_PATHS=("$DIR/variables/basic")
  run kitbash.vars.files.general "GREETING"
  assert_output "hello"
}

@test "kitbash.vars.files.general uses reverse lexical sort for files" {
  KITBASH_VARIABLE_PATHS=("$DIR/variables/basic")
  run kitbash.vars.files.general "DEPARTURE"
  assert_output "departed"
}

@test "kitbash.vars.files.general model script file overrides" {
  # KITBASH_LOG_LEVEL=0
  KITBASH_VARIABLE_PATHS=("$DIR/variables/basic" "$DIR/variables/with_model_script")
  KITBASH_MODEL_INHERITANCE=(modelname)
  KITBASH_CURRENT_MODEL=modelname
  run kitbash.vars.files.general "GREETING"
  assert_output "modelname"
}

@test "kitbash.vars.files.general model directory overrides" {
  # KITBASH_LOG_LEVEL=0
  
  KITBASH_MODEL_INHERITANCE=(modelname)
  KITBASH_VARIABLE_PATHS=("$DIR/variables/basic" "$DIR/variables/with_model_dir")
  KITBASH_CURRENT_MODEL=modelname
  run kitbash.vars.files.general "GREETING"
  assert_output "modelname_directory"
}

@test "info.var returns present value" {
  # KITBASH_LOG_LEVEL=0
  KITBASH_VARIABLE_PATHS=("$DIR/variables/basic")
  run info.var "GREETING"
  assert_output "hello"
}

@test "info.var fails on missing" {
  KITBASH_VARIABLE_PATHS=("$DIR/variables/basic")
  run info.var "MISSING"
  assert_failure 1
}

@test "info.var model script file overrides" {
  # KITBASH_LOG_LEVEL=0
  KITBASH_VARIABLE_PATHS=("$DIR/variables/basic" "$DIR/variables/with_model_script")
  KITBASH_MODEL_INHERITANCE=(modelname)
  KITBASH_CURRENT_MODEL=modelname
  run info.var "GREETING"
  assert_output "modelname"
}