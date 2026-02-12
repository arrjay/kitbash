#shellcheck shell=bash

local ABSOLUTE_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# this should give us system::package and system::package::absent
case "`uname -s`" in
  Linux)
    if [ -e /usr/bin/lsb_release ]; then
      # It's something that adheres to LSB!
      # TODO: things other than Debian derivatives
      case "`lsb_release -is`" in
      Debian)
        ;&
      Ubuntu)
        __kitbash_load_deps_from_path $ABSOLUTE_PATH/apt
        ;;
      esac
    elif [ -e /etc/arch-release ]; then
      # it's Arch Linux! Woo!
      __kitbash_load_deps_from_path $ABSOLUTE_PATH/pacman
    elif [ -e /etc/alpine-release ]; then
      # it's Alpine Linux! Also Woo!
      __kitbash_load_deps_from_path $ABSOLUTE_PATH/apk
    fi
    ;;
  Darwin)
    # Probably macOS
    # Probably _probably_ Homebrew
    __kitbash_load_deps_from_path $ABSOLUTE_PATH/brew
    ;;
  FreeBSD)
    # it's FreeBSD! Neat!
    __kitbash_load_deps_from_path $ABSOLUTE_PATH/freebsd_pkg
    ;;
esac

# handle :: infix functions being the only ones loaded (back-compat for old callers)
declare -f system::package >/dev/null 2>&1 && system.package() { __kitbash_log "called legacy system.package" ; system::package "${@}" ; }
declare -f system::package::absent >/dev/null 2>&1 && system.package.absent() { __kitbash_log "called legacy system.package.absent" ; system::package::absent "${@}" ; }

# handle . infix functions being the only ones that were loaded (forward-compat so new callers work)
declare -f system::package >/dev/null 2>&1 || { declare -f system.package >/dev/null 2>&1 && system::package() { __kitbash_log "legacy system.package provider in use" ; system.package "${@}" ; } ; }
declare -f system::package::absent >/dev/null 2>&1 || { declare -f system.package.absent >/dev/null 2>&1 && system::package::absent() { __kitbash_log "legacy system.package.absent provider in use" ; system.package.absent "${@}" ; } ; }
