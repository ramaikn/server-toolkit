#!/usr/bin/env bash
# Perintah satu baris untuk Linux/macOS/WSL baru yang belum punya git:
#
#   curl -fsSL https://raw.githubusercontent.com/ramaikn/server-toolkit/master/bootstrap.sh | bash
#   curl -fsSL .../bootstrap.sh | bash -s -- --profile full      (argumen diteruskan ke setup.sh)
#
# Memasang git bila perlu, clone (atau update) repo ke ~/code/server-toolkit, lalu menjalankan setup.sh.
# Variabel opsional: TOOLKIT_REPO (URL/folder repo), TOOLKIT_DIR (lokasi clone).

set -euo pipefail

REPO="${TOOLKIT_REPO:-https://github.com/ramaikn/server-toolkit.git}"
DIR="${TOOLKIT_DIR:-$HOME/code/server-toolkit}"

say() { printf '  %s\n' "$*"; }
fail() { printf '  X   %s\n' "$*" >&2; exit 1; }

if [ "$(id -u)" -eq 0 ]; then SUDO=""; elif command -v sudo >/dev/null; then SUDO=sudo; else SUDO=""; fi

install_git() {
  say "Memasang git."
  if [ "$(uname -s)" = Darwin ]; then
    # Memicu pemasangan Command Line Tools (berisi git) bawaan macOS
    xcode-select --install 2>/dev/null || true
    fail "Selesaikan dialog pemasangan Command Line Tools, lalu jalankan perintah ini lagi."
  elif command -v apt-get >/dev/null; then
    $SUDO env DEBIAN_FRONTEND=noninteractive apt-get update -y >/dev/null
    $SUDO env DEBIAN_FRONTEND=noninteractive apt-get install -y git curl ca-certificates >/dev/null
  elif command -v dnf >/dev/null; then $SUDO dnf install -y git curl >/dev/null
  elif command -v yum >/dev/null; then $SUDO yum install -y git curl >/dev/null
  elif command -v pacman >/dev/null; then $SUDO pacman -Sy --needed --noconfirm git curl >/dev/null
  elif command -v zypper >/dev/null; then $SUDO zypper --non-interactive install git curl >/dev/null
  elif command -v apk >/dev/null; then $SUDO apk add git curl bash >/dev/null
  else fail "Package manager tidak dikenali. Pasang git manual lalu jalankan lagi."
  fi
}

command -v git >/dev/null || install_git

if [ -d "$DIR/.git" ]; then
  say "Memperbarui $DIR"
  git -C "$DIR" pull --ff-only --quiet || say "Gagal update (ada perubahan lokal?), memakai versi yang ada."
else
  say "Mengunduh server-toolkit ke $DIR"
  mkdir -p "$(dirname "$DIR")"
  git clone --quiet "$REPO" "$DIR"
fi

# stdin dari pipe curl sudah habis; arahkan ke terminal supaya sudo dan menu interaktif bisa membaca.
# Dicoba buka sungguhan: di sesi tanpa terminal, /dev/tty ada tapi tidak bisa dibuka.
if (exec </dev/tty) 2>/dev/null; then
  exec bash "$DIR/setup.sh" "$@" </dev/tty
else
  exec bash "$DIR/setup.sh" "$@"
fi
