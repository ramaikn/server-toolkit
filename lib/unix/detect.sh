# Deteksi platform. Mengisi variabel global yang dipakai semua tool:
#   OS_KIND   linux | macos | wsl
#   DISTRO_ID, DISTRO_LIKE, DISTRO_NAME  dari /etc/os-release (linux/wsl)
#   ARCH      x64 | arm64 | lainnya (apa adanya dari uname -m)
#   PKG_MGR   apt | dnf | yum | pacman | zypper | apk | brew | none
#   HAS_GUI   1 jika ada layar grafis (macOS selalu 1)
#   SUDO      "" jika root, "sudo" jika user biasa yang punya sudo

detect_platform() {
  local kernel
  kernel="$(uname -s)"
  case "$kernel" in
    Darwin) OS_KIND=macos ;;
    Linux)
      # Container di Docker Desktop memakai kernel WSL, jadi /.dockerenv dicek dulu.
      if [ ! -f /.dockerenv ] && grep -qiE 'microsoft|wsl' /proc/version 2>/dev/null; then
        OS_KIND=wsl
      else
        OS_KIND=linux
      fi ;;
    MINGW*|MSYS*|CYGWIN*)
      die "Ini Windows (Git Bash). Jalankan setup.cmd dari PowerShell atau CMD." ;;
    *) die "OS $kernel belum didukung." ;;
  esac

  case "$(uname -m)" in
    x86_64|amd64) ARCH=x64 ;;
    aarch64|arm64) ARCH=arm64 ;;
    *) ARCH="$(uname -m)" ;;
  esac

  DISTRO_ID=""; DISTRO_LIKE=""; DISTRO_NAME=""
  if [ "$OS_KIND" = macos ]; then
    DISTRO_ID=macos
    DISTRO_NAME="macOS $(sw_vers -productVersion 2>/dev/null)"
  elif [ -r /etc/os-release ]; then
    # shellcheck disable=SC1091
    DISTRO_ID="$(. /etc/os-release && echo "${ID:-}")"
    DISTRO_LIKE="$(. /etc/os-release && echo "${ID_LIKE:-}")"
    DISTRO_NAME="$(. /etc/os-release && echo "${PRETTY_NAME:-$ID}")"
  fi

  PKG_MGR=none
  if [ "$OS_KIND" = macos ]; then
    PKG_MGR=brew
  else
    for m in apt-get dnf yum pacman zypper apk; do
      if has_cmd "$m"; then PKG_MGR="${m%-get}"; break; fi
    done
  fi

  HAS_GUI=0
  if [ "$OS_KIND" = macos ] || [ -n "${DISPLAY:-}" ] || [ -n "${WAYLAND_DISPLAY:-}" ]; then HAS_GUI=1; fi

  if [ "$(id -u)" -eq 0 ]; then
    SUDO=""
  elif has_cmd sudo; then
    SUDO=sudo
  else
    SUDO=none
  fi

  _log_file INFO "platform os=$OS_KIND distro=$DISTRO_ID like=$DISTRO_LIKE arch=$ARCH pkg=$PKG_MGR gui=$HAS_GUI sudo=$SUDO"
}

# Jalankan perintah sebagai root. Gagal jelas kalau tidak ada sudo.
as_root() {
  case "$SUDO" in
    "") run "$@" ;;
    sudo) run sudo "$@" ;;
    *) error "Butuh akses root untuk: $*. Pasang sudo atau jalankan sebagai root."; return 1 ;;
  esac
}

platform_summary() {
  printf '  Sistem   : %s (%s, %s)\n' "${DISTRO_NAME:-$OS_KIND}" "$OS_KIND" "$ARCH"
  printf '  Paket    : %s\n' "$PKG_MGR"
  printf '  Tampilan : %s\n' "$([ "$HAS_GUI" = 1 ] && echo 'ada (desktop)' || echo 'tidak ada (server)')"
}
