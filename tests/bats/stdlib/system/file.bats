load "../../../bats_helpers/bats-support/load"
load "../../../bats_helpers/bats-assert/load"

setup() {
  DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )"
  # load "${DIR}/../../../bin/babashka"
  # load the babashka core functions
  . "${DIR}/../../../../helpers/01-core.sh"
  . "${DIR}/../../../../helpers/02-system_info.sh"
  . "${DIR}/../../../../helpers/03-system.sh"
  if stat --version &>/dev/null; then
    # GNU stat
    stat_flag="-c"
  else
    # BSD/macOS
    stat_flag="-f"
  fi
  uid=$(stat "$stat_flag" '%u' "${DIR}/file/empty_file")
  gid=$(stat "$stat_flag" '%g' "${DIR}/file/empty_file")
}

@test "file has expected uid" {
  run path.has_uid "${DIR}/file/empty_file" $uid
  assert_success
}

@test "file has expected gid" {
  run path.has_gid "${DIR}/file/empty_file" $gid
  assert_success
}

@test "file does not have root uid" {
  run path.has_uid "${DIR}/file/empty_file" 0
  assert_failure
}

@test "file does not have root gid" {
  run path.has_gid "${DIR}/file/empty_file" 0
  assert_failure
}

@test "file has mode 644" {
  run path.has_mode "${DIR}/file/empty_file" 644
  assert_success
}

@test "file has mode 0644" {
  run path.has_mode "${DIR}/file/empty_file" 0644
  assert_success
}

@test "file does not have mode 755" {
  run path.has_mode "${DIR}/file/empty_file" 755
  assert_failure
}