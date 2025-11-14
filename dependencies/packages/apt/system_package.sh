system.package.apt() {
  local _package_name=$1; shift
  
  # Any flags you want to set should be set via apt_flags= outside this
  # call
  __babashka_log "== ${FUNCNAME[0]} $_package_name"
  get_id() {
    echo "${_package_name}"
  }
  is_met() {
    dpkg -s ${apt_pkg:-$_package_name} > /dev/null 2>&1
  }
  meet() {
    [ -n "$__babushka_force" ] && apt_flags="${apt_flags} -f --force-yes"
    DEBIAN_FRONTEND=noninteractive apt-get \
      -o DPkg::Lock::Timeout=60 \
      -yqq install \
      "$apt_flags" \
      "${apt_pkg:-$_package_name}" \
      >/dev/null 2>&1
  }
  process
}

system.package.absent.apt() {
  local _package_name=$1; shift;

  __babashka_log "== ${FUNCNAME[0]} $_package_name"
  get_id() {
    echo "${_package_name}"
  }
  is_met() {
    dpkg -s "${apt_pkg:-$_package_name}" 2>&1 > /dev/null && return 1
    return 0
   }
   meet() {
    [ -n "$__babushka_force" ] && apt_flags="${apt_flags} -f --force-yes"
    DEBIAN_FRONTEND=noninteractive $__babashka_sudo apt-get -o DPkg::Lock::Timeout=60 -yqq remove "$apt_flags" "${apt_pkg:-$_package_name}"
    DEBIAN_FRONTEND=noninteractive $__babashka_sudo apt-get -o DPkg::Lock::Timeout=60 -yqq autoremove
   }
  process
}

# Don't redefine the base functions if we're not Debian-like
# This will pass on Ubuntu as well.

system.info.like "debian" || return

system.package() {
  system.package.apt "$@"
}

system.package.absent() {
  system.package.absent.apt "$@"
}

# system.packages() {
#   
#   local all_pkgs=""
#   for param in "$@"; do
#       # Concatenate each parameter to the string variable, separated by a space
#       all_pkgs+=" $param"
#   done
#   # Trim leading whitespace
#   all_pkgs="${all_pkgs:1}"
#   __babashka_log "${FUNCNAME[0]} (apt) $all_pkgs"
#   
#   local _copy_of_input=("$@");
#   local _missing_packages=()
#   is_met() {
#     for pkg in "${_copy_of_input[@]}"; do
#       if ! dpkg -s ${apt_pkg:-$pkg} 2>&1 > /dev/null; then
#         _missing_packages+=("$pkg")
#       fi
#     done
#     [ ${#_missing_packages[@]} -eq 0 ]
#   }
#   meet() {
#     [ -n "$__babushka_force" ] && apt_flags="${apt_flags} -f --force-yes"
#     printf "%s\n" "${_missing_packages[@]}" | DEBIAN_FRONTEND=noninteractive $__babashka_sudo xargs -d '\n' apt-get -y install
#   }
#   process
# }