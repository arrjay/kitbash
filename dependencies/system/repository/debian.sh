system.repository.apt() {
  system.debian.repo.custom "$@"
}

system.info.like "debian" || return

system.repository() {
  system.debian.repo.custom "$@"
}