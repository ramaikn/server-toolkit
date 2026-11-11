# Lapisan package manager sistem. Tool cukup memanggil pkg_install dengan nama paket
# per manajer; pkg_refresh dijalankan sekali per sesi.

PKG_REFRESHED=0

pkg_refresh() {
  [ "$PKG_REFRESHED" = 1 ] && return 0
  PKG_REFRESHED=1
  case "$PKG_MGR" in
    apt)    DEBIAN_FRONTEND=noninteractive as_root apt-get update -y ;;
    dnf)    as_root dnf makecache -y ;;
    yum)    as_root yum makecache -y ;;
    pacman) as_root pacman -Sy --noconfirm ;;
    zypper) as_root zypper --non-interactive refresh ;;
    apk)    as_root apk update ;;
    brew)   run brew update ;;
    *)      return 1 ;;
  esac
}

pkg_install() {
  [ $# -eq 0 ] && return 0
  pkg_refresh || true
  case "$PKG_MGR" in
    apt)    as_root env DEBIAN_FRONTEND=noninteractive apt-get install -y "$@" ;;
    dnf)    as_root dnf install -y "$@" ;;
    yum)    as_root yum install -y "$@" ;;
    pacman) as_root pacman -S --needed --noconfirm "$@" ;;
    zypper) as_root zypper --non-interactive install "$@" ;;
    apk)    as_root apk add "$@" ;;
    brew)   run brew install "$@" ;;
    *)      error "Package manager tidak dikenali, pasang manual: $*"; return 1 ;;
  esac
}

# Pasang satu per satu dan abaikan yang gagal (paket opsional yang tidak ada di semua distro).
pkg_install_optional() {
  local p
  for p in "$@"; do
    pkg_install "$p" || warn "Paket opsional '$p' tidak tersedia di $PKG_MGR, dilewati."
  done
}
