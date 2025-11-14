load "../../../bats_helpers/bats-support/load"
load "../../../bats_helpers/bats-assert/load"

setup() {
  DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )"
  # load "${DIR}/../../../bin/babashka"
  # load the babashka core functions
  . "${DIR}/../../../../helpers/lib/std/check_constraint.sh"
}

@test "check constraint >" {
  std.check_constraint "3.10" ">3.1"
}

@test "check constraint >=" {
  std.check_constraint "3.10" ">=3.1"
}

@test "check constraint ==" {
  std.check_constraint "3.10" "==3.10"
}

@test "check constraint <" {
  std.check_constraint "3.10" "<3.11"
}

@test "check constraint <=" {
  std.check_constraint "3.10" "<=3.11"
}

@test "check constraint > with whitespace" {
  std.check_constraint "3.10" "> 3.1"
}

@test "check constraint range accepted" {
  std.check_constraint "3.10" "> 3.1, <= 3.11"
}

@test "check pessimistic constraint major constraint" {
  std.check_constraint "3.10.1" "~> 3"
}

@test "check pessimistic constraint minor constraint" {
  std.check_constraint "3.10.1" "~> 3.10"
}

@test "check pessimistic constraint patch constraint" {
  std.check_constraint "3.10.1" "~> 3.10.1"
}
