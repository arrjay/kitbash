load "../../../bats_helpers/bats-support/load"
load "../../../bats_helpers/bats-assert/load"

setup() {
  DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )"
  # load "${DIR}/../../../bin/babashka"
  # load the babashka core functions
  . "${DIR}/../../../../helpers/01-core.sh"
  . "${DIR}/../../../../helpers/02-system_info.sh"
  . "${DIR}/../../../../helpers/03-system.sh"
}

@test "user.get_uid works with username" {
  assert [ "$(user.get_uid root)" = 0 ]
}

@test "user.get_uid works with uid" {
  user.get_uid 0
}

@test "user.get_uid fails on nonexistent uid" {
  run user.get_uid 99999
  assert_failure
}

@test "user.get_uid fails on nonexistent username" {
  run user.get_uid "a_very_long_nonexistent_user"
  assert_failure
}

@test "group.get_gid works with group name" {
  assert [ "$(group.get_gid daemon)" = 1 ]
}

@test "group.get_gid works with gid" {
  group.get_gid 1
}

@test "group.get_gid fails on nonexistent gid" {
  run group.get_gid 99999
  assert_failure
}

@test "group.get_gid fails on nonexistent group name" {
  run group.get_gid "a_very_long_nonexistent_group"
  assert_failure
}