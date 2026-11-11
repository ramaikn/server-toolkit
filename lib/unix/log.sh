# Logging dan eksekusi perintah. Semua output perintah masuk ke file log,
# layar hanya menampilkan pesan ringkas untuk user.

LOG_DIR="$TOOLKIT_ROOT/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/setup-$(date +%Y%m%d-%H%M%S).log"
DRY_RUN="${DRY_RUN:-0}"

if [ -t 1 ]; then
  C_RESET=$'\033[0m'; C_DIM=$'\033[2m'; C_RED=$'\033[31m'; C_GREEN=$'\033[32m'; C_YELLOW=$'\033[33m'; C_BOLD=$'\033[1m'
else
  C_RESET=""; C_DIM=""; C_RED=""; C_GREEN=""; C_YELLOW=""; C_BOLD=""
fi

_log_file() { printf '%s [%s] %s\n' "$(date '+%F %T')" "$1" "$2" >>"$LOG_FILE"; }

info()  { _log_file INFO "$*";  printf '%s\n' "  $*"; }
ok()    { _log_file INFO "$*";  printf '%s\n' "  ${C_GREEN}OK${C_RESET}  $*"; }
warn()  { _log_file WARN "$*";  printf '%s\n' "  ${C_YELLOW}!${C_RESET}   $*" >&2; }
error() { _log_file ERROR "$*"; printf '%s\n' "  ${C_RED}X${C_RESET}   $*" >&2; }
die()   { error "$*"; exit 1; }
title() { _log_file INFO "== $* =="; printf '\n%s\n' "${C_BOLD}$*${C_RESET}"; }

# Jalankan perintah, output ke log. Saat --dry-run hanya ditampilkan.
run() {
  if [ "$DRY_RUN" = 1 ]; then
    printf '%s\n' "  ${C_DIM}[dry-run] $*${C_RESET}"
    return 0
  fi
  _log_file CMD "$*"
  "$@" >>"$LOG_FILE" 2>&1
}

# Ulangi perintah sampai berhasil. Jaringan server baru sering putus di tengah
# unduhan (curl partial file / SSL reset), jadi installer dicoba ulang dengan jeda.
#   retry <jumlah> <perintah...>
retry() {
  local max="$1" n=1
  shift
  while true; do
    "$@" && return 0
    [ "$n" -ge "$max" ] && return 1
    warn "Gagal (percobaan $n dari $max), mencoba lagi dalam $((n * 5)) detik."
    sleep $((n * 5))
    n=$((n + 1))
  done
}

has_cmd() { command -v "$1" >/dev/null 2>&1; }

# Tanya ya/tidak. ASSUME_YES=1 (flag --yes) selalu menjawab default yes.
confirm() {
  local prompt="$1" default="${2:-y}" reply
  if [ "${ASSUME_YES:-0}" = 1 ]; then return 0; fi
  if [ ! -t 0 ]; then [ "$default" = y ]; return; fi
  read -r -p "  $prompt [$( [ "$default" = y ] && echo Y/n || echo y/N )] " reply
  reply="${reply:-$default}"
  [[ "$reply" =~ ^[Yy] ]]
}
