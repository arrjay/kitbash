# log.sh — simple structured logger for Kitbash

# Default log destination
: "${KITBASH_LOG_FILE:=}"

# Optional default colour toggle inherited by str.
: "${KITBASH_NO_COLOR:=}"

EMIT_ENABLED="${EMIT_ENABLED:-1}"

: "${KITBASH_LOG_TIMESTAMP:-0}"
# Set logging levels

declare -Ag LOG_LEVELS=(
  [debug]=0
  [info]=1
  [warn]=2
  [error]=3
)
# Default log level is warn
# : "${KITBASH_LOG_LEVEL:-2}"
# If it's set elsewhere, otherwise we default to warn
KITBASH_LOG_LEVEL="${KITBASH_LOG_LEVEL:-2}"
__KITBASH_CURRENT_INDENT="${__KITBASH_CURRENT_INDENT:0}"


# --- internal: open log stream ---
log.__open() {
  # If KITBASH_LOG_FILE is set, open it for append
  if [[ -n "$KITBASH_LOG_FILE" ]]; then
    exec {__log_fd}>>"$KITBASH_LOG_FILE"
    export KITBASH_NO_COLOR=1
  else
    __log_fd=2 # stderr
  fi
}

log.__set_fd() {
  # Allows us to set the FD arbitrarily.
  # Useful for logging during bats runs.
  __log_fd="$1"
}

# --- internal: close log stream ---
log.__close() {
  [[ -n "$KITBASH_LOG_FILE" ]] && exec {__log_fd}>&-
}

# --- internal: timestamp ---
log.__timestamp() {
  date '+%Y-%m-%d %H:%M:%S'
}

log.__level_lookup() {
  case "$1" in
    debug|DEBUG)
      echo "${LOG_LEVELS[debug]}" ;;
    info|INFO)
      echo "${LOG_LEVELS[info]}" ;;
    warn|WARN)
      echo "${LOG_LEVELS[warn]}" ;;
    error|ERROR)
      echo "${LOG_LEVELS[error]}" ;;
  esac
}

log.level() {
  case "$1" in
    debug|DEBUG)
      KITBASH_LOG_LEVEL="${LOG_LEVELS[debug]}" ;;
    info|INFO)
      KITBASH_LOG_LEVEL="${LOG_LEVELS[info]}" ;;
    warn|WARN)
      KITBASH_LOG_LEVEL="${LOG_LEVELS[warn]}" ;;
    error|ERROR)
      KITBASH_LOG_LEVEL="${LOG_LEVELS[error]}" ;;
    *)
      echo "$KITBASH_LOG_LEVEL" ;;
  esac
}

# --- internal: write line ---
log.__write() {
  local level="$1"; shift
  local message="$*"
  
  local context
  context="$(log.__callsite)"
  [[ -n "$KITBASH_CONTEXT" ]] && 
    context="$context $KITBASH_CONTEXT"
  
  # printf '%s %s [%s] %s\n' \
  #   "[$(log.__timestamp)]" \
  #   "$context" \
  #   "$level" \
  #   "$message" >&$__log_fd

  printf '%s [%s] %s\n' \
    "$context" \
    "$level" \
    "$message" >&$__log_fd
}

# log.__callsite
# Usage: log.__callsite
# Internal function. Returns the callsite of where the logger was called.
log.__callsite() {
  local depth=0
  while [[ "${FUNCNAME["$depth"]}" == log.* || "${FUNCNAME["$depth"]}" == emit* ]]; do
    ((depth++))
  done
  local func="${FUNCNAME["$depth"]:-main}"
  local file="${BASH_SOURCE["$depth"]:-?}"
  local line="${BASH_LINENO[(($depth-1))]:-?}"
  printf '(%s %s:%s)' "$(basename "$file")" "$func" "$line" 
}

# Test if we should log

log.__should_log() {
  local level
  level="$1"
  # If we're not high enough to log, no-op
  # echo "incoming level: $level" >&2
  level=$(log.__level_lookup "$level")
  [[ "$KITBASH_LOG_LEVEL" -le "$level" ]]

}

# --- levels ---
log.debug() {
  log.__should_log debug || return 0
  log.__write "$(str.dim "DEBUG")" "$*"
}

log.info() {
  log.__should_log info || return 0
  log.__write "$(str.bright-blue "INFO")" "$*"
}

log.warn() {
  log.__should_log warn || return 0
  log.__write "$(str.yellow "WARN")" "$*"
}

log.error() {
  log.__should_log error || return 0
  log.__write "$(str.color bold red -- "ERROR")" "$*"
}

# --- setup ---
log.__open
trap log.__close EXIT


#
# emit
# Functions for emitting to userspace, instead of using echo or printf
# directly.
# Allows a measure of control over whether or not we're allowing output,
# since -q is expected to quiet the program.
#

# Global flag controlled by -q / --quiet

emit() {

  local level="$1"; shift   # e.g. apply, ok, error
  local msg="$*"
  if [[ -z "$msg" && ! -t 0 ]]; then
    msg="$(cat)"  # read full stdin, preserving all whitespace
  fi
  emit.indented "$__KITBASH_CURRENT_INDENT" "$level" "$msg"
}

emit.indented() {
  # exit early if suppressed
  local indent="$1"; shift
  local level="$1"; shift   # e.g. apply, ok, error
  local msg="$*"
  if [[ -z "$msg" && ! -t 0 ]]; then
    msg="$(cat)"  # read full stdin, preserving all whitespace
  fi
  # [[ -n "$KITBASH_CONTEXT" ]] && printf "[%s] " "$KITBASH_CONTEXT"
  local icon
  case "$level" in
    header)
      icon="$(str.color bold -- "—")"
      ;;
    apply)
      icon="$(str.color bright-blue bold -- "→")"
      log.info emit apply "$msg"
      ;;
    ok)
      icon="$(str.color bold green -- ✓)" 
      log.info emit apply "$msg"
      ;;
    no)
      icon="$(str.color bright-yellow bold -- o)"
      log.info emit apply "$msg"
      ;;
    error)
      icon="$(str.color red -- ✗)"
      log.error emit error "$msg"
      ;;
    info)
      icon="$(str.color bold -- i)"
      log.info emit info "$msg"
      ;;
    *)
      icon="$(str.color bold -- ?)"
      log.warn emit "unknown level $level"
      log.info emit "$level" "$msg"
      ;;
  esac
  # Emit enabled is down here so that we still attempt to log out
  [[ "$EMIT_ENABLED" -eq 0 ]] && return 0
  printf "%*s"  "$indent"
  printf "%s %s\n" "$icon" "$msg"
}