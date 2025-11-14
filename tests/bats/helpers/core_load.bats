DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )"
load "../../bats_helpers/bats-support/load"
load "../../bats_helpers/bats-assert/load"
# load "../../helpers/system_info.sh"

setup() {
  DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )"
  
  # Load Babashka itself
  # . "${DIR}/../../../bin/babashka"
  # load the bats helpers
  . "${DIR}/../../../helpers/01-core.sh"
  export KITBASH_TEST_CALLER="$BATS_TEST_FILENAME"
}

teardown() {
  unset KITBASH_TEST_CALLER
  unset TEST_VARIABLE
}

@test "kitbash.load loads a fully relative path" {
  kitbash.load files/a_file
  # echo "$output"
  assert_equal "$TEST_VARIABLE" test
}

@test "kitbash.load loads a dotted path" {
  kitbash.load ./files/a_file
  assert_equal "$TEST_VARIABLE" test
}

@test "kitbash.load loads a symlink" {
  kitbash.load ./files/depth_1/symlink
  assert_equal "$TEST_VARIABLE" test
}

@test "kitbash.load fails to load a nonexistent file" {
  refute kitbash.load no/such/file
}