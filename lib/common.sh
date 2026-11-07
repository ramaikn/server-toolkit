#!/usr/bin/env bash
# Fungsi bersama untuk semua skrip. Di-source, bukan dijalankan langsung.

TOOLKIT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_DIR="$TOOLKIT_ROOT/logs"
LOG_FILE="$LOG_DIR/toolkit.log"
mkdir -p "$LOG_DIR"

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
