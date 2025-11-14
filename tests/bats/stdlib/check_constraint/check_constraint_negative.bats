load "../../../bats_helpers/bats-support/load"
load "../../../bats_helpers/bats-assert/load"

setup() {
  DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )"
  # load "${DIR}/../../../bin/babashka"
  # load the babashka core functions
  . "${DIR}/../../../../helpers/lib/std/check_constraint.sh"
}

@test "check constraint > fails" {
  run std.check_constraint "3.10" ">3.12"
  assert_failure
}

@test "check constraint >= fails" {
  run std.check_constraint "3.10" ">=3.12"
  assert_failure
}

@test "check constraint == on major fails" {
  run std.check_constraint "3.10" "==4"
  assert_failure
}

@test "check constraint == on minor fails" {
  run std.check_constraint "3.10" "==3.11"
  assert_failure
  run std.check_constraint "3.10" "==3.12"
  assert_failure
}

@test "check constraint == on patch fails" {
  run std.check_constraint "3.10" "==3.10.1"
  assert_failure
  run std.check_constraint "3.10" "==3.11.1"
  assert_failure
}

@test "check constraint < major fails" {
  run std.check_constraint "5" "<4"
  assert_failure
}
@test "check constraint < minor fails" {
  run std.check_constraint "3.12" "<3.11"
  assert_failure
}
@test "check constraint < patch fails" {
  run std.check_constraint "3.11" "<3.10.1"
  assert_failure
}

@test "check constraint <= fails" {
  run std.check_constraint "3.10" "<=3.9"
  assert_failure
}

@test "check constraint range fails" {
  run std.check_constraint "3.9" "> 3.10, <= 3.12"
  assert_failure
}

@test "check pessimistic constraint major constraint fails" {
  run std.check_constraint "3.10.1" "~> 4"
  assert_failure
}

@test "check pessimistic constraint minor constraint fails" {
  run std.check_constraint "3.10.1" "~> 3.11"
  assert_failure
}

@test "check pessimistic constraint patch constraint fails" {
  run std.check_constraint "3.10.1" "~> 3.10.2"
  assert_failure
}
