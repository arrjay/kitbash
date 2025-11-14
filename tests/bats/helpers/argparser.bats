load "../../bats_helpers/bats-support/load"
load "../../bats_helpers/bats-assert/load"

setup_file() {
  DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )"
  # load "${DIR}/../../../bin/babashka"
  # load the babashka core functions
  . "${DIR}/../../../helpers/01-core.sh"
  . "${DIR}/../../../helpers/typechecker.sh"
}

setup() {
  DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )"
  . "${DIR}/../../../helpers/00-color.sh"
  . "${DIR}/../../../helpers/00-log.sh"
  . "${DIR}/../../../helpers/01-core.sh"
  . "${DIR}/../../../helpers/argparser.sh"
  . "${DIR}/../../../helpers/typechecker.sh"
  KITBASH_NO_COLOR=1
}

teardown() {
  unset OPTIONS
  unset XOR
  unset options
}

# declare -A OPTIONS=(
  # ["s|source;string"]=""
  # ["m|mode;mode"]="644"
  # ["o|owner;string"]="root"
  # ["g|group;string"]="root"
  # ["c|contents;string"]=""
# )
# declare -a XOR=( "source,contents" )
@test "std.argparser parses shortform" {
  declare -A OPTIONS=(
    ["s"]=""
  )
  std.argparser s "hello"
  # the `options` associative array should now be defined
  assert_equal "${options["s"]}" "hello"
}

@test "std.argparser parses longform" {
  declare -A OPTIONS=(
    ["source"]=""
  )
  std.argparser source "hello"
  # the `options` associative array should now be defined
  assert_equal "${options["source"]}" "hello"
}

@test "std.argparser normalizes to longform" {
  declare -A OPTIONS=(
    ["s|source"]=""
  )
  std.argparser s "hello"
  # the `options` associative array should now be defined
  assert_equal "${options["source"]}" "hello"
}

@test "std.argparser default is set" {
  declare -A OPTIONS=(
    ["s|source"]="hello"
  )
  std.argparser
  # the `options` associative array should now be defined
  assert_equal "${options["source"]}" "hello"
}

@test "std.argparser default is overridden" {
  declare -A OPTIONS=(
    ["s|source"]="hello"
  )
  std.argparser source "goodbye"
  # the `options` associative array should now be defined
  assert_equal "${options["source"]}" "goodbye"
}

@test "std.argparser XOR prevents opposing keys" {
  declare -A OPTIONS=(
    ["g|greeting"]="hello"
    ["d|departure"]="goodbye"
  )
  declare -a XOR=( "greeting,departure" )
  
  refute std.argparser greeting "bonjour" \
    departure "au revoir"
}

@test "std.argparser XOR allows one key" {
  declare -A OPTIONS=(
    ["g|greeting"]=""
    ["d|departure"]=""
  )
  declare -a XOR=( "greeting,departure" )
  
  assert std.argparser greeting "bonjour"
}

@test "std.argparser XOR clears on subsequent runs" {
  declare -A OPTIONS=(
    ["g|greeting"]=""
    ["d|departure"]=""
  )
  declare -a XOR=( "greeting,departure" )
  
  assert std.argparser greeting "bonjour"
  assert_equal $options["greeting"] "bonjour"
  assert std.argparser departure "au revoir"
  assert_equal $options["departure"] "au revoir"
}

## Successful Argument Typechecking

@test "std.argparser typecheck string succeeds" {
  declare -A OPTIONS=(
    ["s|source;string"]="hello"
  )
  std.argparser source "goodbye"
  # the `options` associative array should now be defined
  assert_equal "${options["source"]}" "goodbye"
}

@test "std.argparser typecheck int succeeds" {
  declare -A OPTIONS=(
    ["i|int;int"]=""
  )
  std.argparser int 1
  # the `options` associative array should now be defined
  assert_equal "${options["int"]}" 1
}

@test "std.argparser typecheck bool succeeds on longform" {
  declare -A OPTIONS=(
    ["b|boolean_true;bool"]=""
    ["f|boolean_false;bool"]=""
  )
  assert std.argparser \
    boolean_true "true" \
    boolean_false "false"
  # the `options` associative array should now be defined
  assert_equal "${options["boolean_true"]}" "true"
  assert_equal "${options["boolean_false"]}" "false"
}

@test "std.argparser typecheck bool succeeds on shortform" {
  declare -A OPTIONS=(
    ["b|boolean_true;bool"]=""
    ["f|boolean_false;bool"]=""
  )
  assert std.argparser \
    boolean_true "t" \
    boolean_false "f"
  # the `options` associative array should now be defined
  assert_equal "${options["boolean_true"]}" "t"
  assert_equal "${options["boolean_false"]}" "f"
}

@test "std.argparser typecheck bool succeeds on int" {
  declare -A OPTIONS=(
    ["b|boolean_true;bool"]=""
    ["f|boolean_false;bool"]=""
  )
  assert std.argparser \
    boolean_true 1 \
    boolean_false 0
  # the `options` associative array should now be defined
  assert_equal "${options["boolean_true"]}" 1
  assert_equal "${options["boolean_false"]}" 0
}

@test "std.argparser typecheck mode succeeds on octal" {
  declare -A OPTIONS=(
    ["z|zero_mode;mode"]=""
    ["m|mode;mode"]=""
  )
  assert std.argparser \
    zero_mode "0644" \
    mode 644
    
  # the `options` associative array should now be defined
  assert_equal "${options["zero_mode"]}" "0644"
  assert_equal "${options["mode"]}" "644"
}

@test "std.argparser typecheck mode succeeds on text" {
  declare -A OPTIONS=(
    ["m|mode;mode"]=""
    ["s|simple_mode;mode"]=""
  )
  assert std.argparser \
    mode "u+x,g-w" \
    simple_mode "u+x"
    
  assert_equal "${options["mode"]}" "u+x,g-w"
  assert_equal "${options["simple_mode"]}" "u+x"
}

@test "std.argparser typecheck file succeeds on file" {
  declare -A OPTIONS=(
    ["f|file;file"]=""
  )
  echo "$DIR"
  assert std.argparser \
    file "$DIR"/files/a_file
  # the `options` associative array should now be defined
  assert_equal "${options["file"]}" "$DIR"/files/a_file
}

@test "std.argparser typecheck path succeeds on path" {
  declare -A OPTIONS=(
    ["p|pathy;path"]=""
  )
  assert std.argparser \
    pathy "$(pwd)"
  # the `options` associative array should now be defined
  assert_equal "${options["pathy"]}" "$(pwd)"
}

@test "std.argparser typecheck ipaddr succeeds on address" {
  declare -A OPTIONS=(
    ["a|address;ipaddr"]=""
  )
  assert std.argparser \
    address "192.168.1.1"
  # the `options` associative array should now be defined
  assert_equal "${options["address"]}" "192.168.1.1"
}

#
## Failure argument typechecking
#

@test "std.argparser typecheck NOT int fails" {
  declare -A OPTIONS=(
    ["i|int;int"]=""
  )
  refute std.argparser int "hello"
}

@test "std.argparser typecheck NOT bool fails on text" {
  declare -A OPTIONS=(
    ["b|boolean_true;bool"]=""
  )
  refute std.argparser \
    boolean_true "not true"
}

@test "std.argparser typecheck NOT file fails" {
  declare -A OPTIONS=(
    ["f|file;file"]=""
  )
  refute std.argparser \
    file "not a file"
}

@test "std.argparser typecheck NOT path fails" {
  declare -A OPTIONS=(
    ["p|pathy;path"]=""
  )
  refute std.argparser \
    pathy "not a path"
}

@test "std.argparser typecheck NOT mode octal fails" {
  declare -A OPTIONS=(
    ["m|mode;mode"]=""
  )
  refute std.argparser \
    mode 999
  refute std.argparser \
    mode 0999
}

@test "std.argparser typecheck NOT mode text fails" {
  declare -A OPTIONS=(
    ["m|mode;mode"]=""
  )
  refute std.argparser \
    mode "a+a"
  refute std.argparser \
    mode "u+w,a+a"
}

@test "std.argparser typecheck NOT ipaddr fails" {
  declare -A OPTIONS=(
    ["a|address;ipaddr"]=""
  )
  refute std.argparser \
    address "not an address"
}