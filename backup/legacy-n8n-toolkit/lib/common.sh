#!/usr/bin/env bash
# Fungsi bersama untuk semua skrip. Di-source, bukan dijalankan langsung.

TOOLKIT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_DIR="$TOOLKIT_ROOT/logs"
LOG_FILE="$LOG_DIR/toolkit.log"
mkdir -p "$LOG_DIR"

# Lokasi stack n8n di server. Bisa diganti: INSTALL_DIR=/lokasi/lain sudo -E bash backup.sh
INSTALL_DIR="${INSTALL_DIR:-/opt/n8n-stack}"

# Tulis ke layar dan ke logs/toolkit.log. Level: INFO, WARN, ERROR.
log() {
  local level="$1"; shift
  local line
  line="$(date '+%Y-%m-%d %H:%M:%S') [$level] $*"
  echo "$line" | tee -a "$LOG_FILE"
}

info() { log INFO "$@"; }
warn() { log WARN "$@"; }

# Berhenti dengan pesan yang bisa dipahami user.
die() {
  log ERROR "$@"
  exit 1
}

# Pastikan stack sudah terpasang dan database berjalan sebelum backup/restore.
require_stack() {
  command -v docker >/dev/null || die "Docker tidak terpasang. Jalankan install.sh dulu."
  [ -f "$INSTALL_DIR/compose.yaml" ] || die "Tidak ada $INSTALL_DIR/compose.yaml. Jalankan install.sh dulu, atau set INSTALL_DIR."
  if ! (cd "$INSTALL_DIR" && docker compose ps --status running --services 2>/dev/null | grep -qx db); then
    die "Layanan db tidak berjalan atau izin kurang. Coba dengan sudo, atau cek: cd $INSTALL_DIR && docker compose ps"
  fi
}

# ask_yes_no "pertanyaan" default(y/n) -> status 0 jika ya.
ask_yes_no() {
  local question="$1" default="${2:-y}" answer hint
  [ "$default" = "y" ] && hint="Y/n" || hint="y/N"
  read -r -p "$question [$hint] " answer || true
  answer="${answer:-$default}"
  [[ "$answer" =~ ^[Yy]$ ]]
}

# ask_value "pertanyaan" "default" -> mencetak nilai yang dipilih.
ask_value() {
  local question="$1" default="$2" answer
  read -r -p "$question [$default] " answer || true
  echo "${answer:-$default}"
}
