# Docker + Compose. Linux: skrip resmi get.docker.com untuk distro yang didukung,
# paket distro untuk sisanya. macOS: Docker Desktop lewat Homebrew.

docker_check()   { has_cmd docker && docker compose version >/dev/null 2>&1; }
docker_version() { docker --version 2>/dev/null; }

_docker_linux_install() {
  case "$DISTRO_ID" in
    ubuntu|debian|raspbian|fedora|centos|rhel)
      run_remote_script https://get.docker.com root:sh && return 0
      warn "get.docker.com gagal, mencoba paket distro." ;;
  esac
  case "$PKG_MGR" in
    apt)     pkg_install docker.io && pkg_install docker-compose-v2 ;;
    dnf|yum) pkg_install moby-engine docker-compose || pkg_install docker docker-compose ;;
    pacman)  pkg_install docker docker-compose ;;
    zypper)  pkg_install docker docker-compose ;;
    apk)     pkg_install docker docker-cli-compose ;;
    *)       error "Tidak tahu cara memasang Docker di distro ini."; return 1 ;;
  esac
}

_docker_enable_service() {
  if has_cmd systemctl && [ -d /run/systemd/system ]; then
    as_root systemctl enable --now docker
  elif has_cmd rc-update; then
    as_root rc-update add docker default && as_root service docker start
  else
    warn "Service Docker belum otomatis jalan (systemd tidak aktif). Jalankan: sudo service docker start"
  fi
  # Supaya docker bisa dipakai tanpa sudo setelah login ulang
  if [ "$SUDO" = sudo ]; then
    as_root usermod -aG docker "$(id -un)"
  fi
}

docker_install() {
  if [ "$OS_KIND" = macos ]; then
    run brew install --cask docker || return 1
    run open -a Docker || true
    warn "Buka aplikasi Docker sekali dan tunggu sampai siap sebelum memakai n8n."
    return 0
  fi
  if [ "$OS_KIND" = wsl ] && has_cmd docker.exe; then
    warn "Docker Desktop Windows terdeteksi. Aktifkan WSL integration di Docker Desktop, jangan pasang Docker kedua."
    return 1
  fi
  _docker_linux_install && _docker_enable_service
}

docker_hint() {
  [ "$OS_KIND" = macos ] && return
  echo "Docker: logout lalu login lagi agar perintah docker bisa dipakai tanpa sudo."
}
