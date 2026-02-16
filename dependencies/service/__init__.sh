local ABSOLUTE_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

case "`uname -s`" in
  Linux)
    if [ -e /usr/bin/lsb_release ]; then
      # It's something that adheres to LSB!
      # However, this should make some more tests to see if it's new enough
      # that it's actually running systemd, since it might not be
      # and that's important to know.
      case "`lsb_release -is`" in
      Debian)
        ;&
      Fedora)
        ;&
      Ubuntu)
        __kitbash_load_deps_from_path $ABSOLUTE_PATH/systemd
        ;;
      esac
    elif [ -e /etc/alpine-release ]; then
      # it's Alpine Linux! Also Woo!
      # Also this should get checked for whether or not it's running
      # openrc. I'm pretty sure all Alpine releases do? But who knows really.
      __kitbash_load_deps_from_path $ABSOLUTE_PATH/openrc
    fi
    ;;
  # Darwin)
  #   # Probably macOS
  #   # TODO: Support launchctl here.
  #   ;;
  FreeBSD)
    __kitbash_load_deps_from_path $ABSOLUTE_PATH/sysrc
  ;;
esac

# forward/backward compat shim
__compat_shim "called legacy system.service.enable"  system.service.enable system::service::enable
__compat_shim "called legacy system.service.disable" system.service.disable system::service::disable
__compat_shim "called legacy system.service.started" system.service.started system::service::started
__compat_shim "called legacy system.service.stopped" system.service.stopped system::service::stopped

fn_exists system::service::enable  || __compat_shim "legacy system.service.enable provider in use"  system::service::enable system.service.enable
fn_exists system::service::disable || __compat_shim "legacy system.service.disable provider in use" system::service::disable system.service.disable
fn_exists system::service::started || __compat_shim "legacy system.service.started provider in use" system::service::started system.service.started
fn_exists system::service::stopped || __compat_shim "legacy system.service.stopped provider in use" system::service::stopped system.service.stopped
