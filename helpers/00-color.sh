# str.colors
# Basic ANSI colour and style helpers for Kitbash

# --- escape codes ---
__start="\033["
__reset="\033[0m"
declare -Ag CODES=(
  # Formats
  [bold]="1"
  [dim]="2"
  [italic]="3"
  [underline]="4"
  # colors
  [black]="30"
  [red]="31"
  [green]="32"
  [yellow]="33"
  [blue]="34"
  [magenta]="35"
  [cyan]="36"
  [white]="37"
  # background colors
  [bg-black]="40"
  [bg-red]="41"
  [bg-green]="42"
  [bg-yellow]="43"
  [bg-blue]="44"
  [bg-magenta]="45"
  [bg-cyan]="46"
  [bg-white]="47"
  
  # high-intensity colors
  [bright-black]="90" # bright-black?
  [bright-red]="91"
  [bright-green]="92"
  [bright-yellow]="93"
  [bright-blue]="94"
  [bright-magenta]="95"
  [bright-cyan]="96"
  [bright-white]="97"
  # bright / high-intensity background colors
  [bg-bright-black]="100"
  [bg-bright-red]="101"
  [bg-bright-green]="102"
  [bg-bright-yellow]="103"
  [bg-bright-blue]="104"
  [bg-bright-magenta]="105"
  [bg-bright-cyan]="106"
  [bg-bright-white]="107"
)


# str.supports_color
# Usage: str.supports_color
# Returns 0 if colour should be enabled, 1 if not.
str.supports_color() {
  # is stderr a tty?
  [[ -t 2 ]] || return 1
  # Otherwise, we're explicitly disabling colours from outside the script
  [[ -z "${NOCOLOR:-}" ]] || return 1
  # Other otherwise, kitbash is explicitly disabling colours.
  # This will happen either via /etc/default/kitbash, or via a logging output
  # file being created, which sets this variable.
  [[ -z "${KITBASH_NO_COLOR:-}" ]] || return 1
  return 0
}

# str.color — compose multiple ANSI attributes in one go
# Usage: str.color <attr...> -- <text>
str.color() {
  local code text
  local codes
  codes=()
  for code in "$@"; do
    if [[ "$code" == "--" || "$code" == "-" ]]; then
      # We've loaded all the codes from our input, so we can assume anything
      # else is just the text
      shift # Pull the entry off of array
      break
    fi
    # Ignore invalid codes for now
    ! [[ -v CODES["$code"] ]] && continue
    # add the code to our list of codes.
    codes+=( "${CODES["$code"]}" )
    shift
  done
  # okay, $* is now just the text
  text="$*"
  # compress the codepoints to a ;-delimited string
  local codepoints
  codepoints=$(IFS=";" ; echo "${codes[*]}")
  # If we allow color, then...
  if str.supports_color; then
    colorized="$__start$codepoints"
    printf '%bm%s%b' "$colorized" "$text" "$__reset"
  else
    # oh, no, no color allowed, so just print the text.
    printf '%s' "$text"
  fi
}

# format helpers
str.bold()      { str.color "bold"      -- "$*"; }
str.dim()       { str.color "dim"       -- "$*"; }
str.italic()    { str.color "italic"    -- "$*"; }
str.underline() { str.color "underline" -- "$*"; }

# standard color helpers
str.black()     { str.color "black"     -- "$*"; }
str.red()       { str.color "red"       -- "$*"; }
str.green()     { str.color "green"     -- "$*"; }
str.yellow()    { str.color "yellow"    -- "$*"; }
str.blue()      { str.color "blue"      -- "$*"; }
str.magenta()   { str.color "magenta"   -- "$*"; }
str.cyan()      { str.color "cyan"      -- "$*"; }
str.white()     { str.color "white"     -- "$*"; }

# high-intensity colour helpers
str.bright-black()     { str.color "bright-black"     -- "$*"; }
str.bright-red()       { str.color "bright-red"       -- "$*"; }
str.bright-green()     { str.color "bright-green"     -- "$*"; }
str.bright-yellow()    { str.color "bright-yellow"    -- "$*"; }
str.bright-blue()      { str.color "bright-blue"      -- "$*"; }
str.bright-magenta()   { str.color "bright-magenta"   -- "$*"; }
str.bright-cyan()      { str.color "bright-cyan"      -- "$*"; }
str.bright-white()     { str.color "bright-white"     -- "$*"; }

