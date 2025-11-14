load "../../bats_helpers/bats-support/load"
load "../../bats_helpers/bats-assert/load"

setup_file() {
  DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )"
  # load "${DIR}/../../../bin/babashka"
  # load the babashka core functions
  . "${DIR}/../../../helpers/00-color.sh"
  . "${DIR}/../../../helpers/00-log.sh"
  . "${DIR}/../../../helpers/01-core.sh"
}

setup() {
  DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )"
  . "${DIR}/../../../helpers/00-color.sh"
  . "${DIR}/../../../helpers/00-log.sh"
  . "${DIR}/../../../helpers/01-core.sh"
  # Lets bats capture our logging information
  # log.__set_fd 3
  # KITBASH_LOG_LEVEL=0
}

teardown() {
  unset test_array
  unset reversed_array
  unset new_array
}

@test "element_in_array detects element" {
  test_array=(one two three four)
  assert bb.core.element_in_array one "${test_array[@]}"
}

@test "types.array.contains detects element" {
  test_array=(one two three four)
  assert types.array.contains test_array one
}

@test "element_in_array rejects missing element" {
  test_array=(one two three four)
  refute bb.core.element_in_array five "${test_array[@]}"
}

@test "types.array.exists fails on absent array" {
  refute types.array.exists "test_array"
}

@test "types.array.exists succeeds on present array" {
  test_array=(one two three four)
  assert types.array.exists "test_array"
}

@test "types.array.reverse reverses array" {
  declare -a test_array=(one two three four)
  reversed_array=(four three two one)
  # declare -a new_array
  local len="${#reversed_array[@]}"
  local i=0
  for val in $(types.array.reverse "test_array"); do
    assert_equal "${reversed_array[$i]}" "$val"
    (( i++ )) || true
  done
}