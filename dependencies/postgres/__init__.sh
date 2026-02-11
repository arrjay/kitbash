local ABSOLUTE_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

case "`uname -s`" in
  Linux)
    if [ -e /usr/bin/lsb_release ]; then
      # It's something that adhers to LSB!
      # TODO: things other than Debian derivatives
      case "`lsb_release -is`" in
      Debian)
        ;&
      Ubuntu)
        __kitbash_load_deps_from_path $ABSOLUTE_PATH/debian
        ;;
      esac
    elif [ -e /etc/arch-release ]; then
      # it's Arch Linux! Woo!
      __kitbash_load_deps_from_path $ABSOLUTE_PATH/arch
    fi
    ;;
  Darwin)
    # Probably macOS
    # Probably _probably_ Homebrew
    __kitbash_load_deps_from_path $ABSOLUTE_PATH/darwin
    ;;
esac

# TODO
# Add other systems here
