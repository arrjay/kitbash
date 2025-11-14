# std.check_constraint
#
# Expands and checks version constraints including pessimistic (~>) syntax.
# Supports comparisons like:
#   ~> 3.10.2  → >=3.10.2 <3.11.0
#   >= 3.12
#   = 3.11.0
#
# Usage:
#   std.check_constraint "<actual_version>" "<constraint>"
#
# Returns:
#   0 if the actual version satisfies the constraint
#   1 otherwise

std.check_constraint() {
  local actual="$1"
  local constraint="$2"
  
  # Normalize: strip all spaces
  constraint="${constraint//[[:space:]]/}"
  
  local op="${constraint%%[0-9]*}"
  local target="${constraint#$op}"

  if [[ "$constraint" == '~>'* ]]; then
    local raw="${constraint#~>}"
    IFS='.' read -r major minor patch <<<"$raw"
    major="${major:-0}"
    minor="${minor:-0}"
    patch="${patch:-0}"
    
    local min="${major}.${minor}.${patch}"
    local max=""
    if [[ -n "$patch" && "$patch" != "0" ]]; then
      max="${major}.$((minor + 1)).0"
    else
      (( major += 1))
      max="${major}.0.0"
    fi

    std.check_constraint "$actual" ">=$min" && std.check_constraint "$actual" "<$max"
    return $?
  fi

  local op="${constraint%%[0-9]*}"
  local target="${constraint#$op}"

  case "$op" in
    "="|"==") [[ "$actual" == "$target" ]] ;;
    ">=") [[ "$(printf "%s\n%s" "$target" "$actual" | sort -V | tail -n1)" == "$actual" ]] ;;
    "<=") [[ "$(printf "%s\n%s" "$target" "$actual" | sort -V | head -n1)" == "$actual" ]] ;;
    ">")  [[ "$actual" != "$target" && "$(printf "%s\n%s" "$target" "$actual" | sort -V | tail -n1)" == "$actual" ]] ;;
    "<")  [[ "$actual" != "$target" && "$(printf "%s\n%s" "$target" "$actual" | sort -V | head -n1)" == "$actual" ]] ;;
    *) echo "std.check_constraint: unknown operator in '$constraint'" >&2; return 1 ;;
  esac
}
