# PATH dan unduhan. Semua tool per-user ditaruh di folder home, lalu satu blok
# bertanda di ~/.bashrc, ~/.zshrc, ~/.profile memastikan foldernya ada di PATH
# untuk terminal baru. Blok ditulis ulang tiap jalan supaya tidak menumpuk.

export FNM_DIR="${FNM_DIR:-$HOME/.local/share/fnm}"
NPM_USER_PREFIX="$HOME/.npm-global"

# Urutan = prioritas. Folder yang belum ada tetap dicantumkan, aman untuk PATH.
USER_BIN_DIRS=(
  "$HOME/.local/bin"
  "$HOME/.opencode/bin"
  "$HOME/.bun/bin"
  "$FNM_DIR"
  "$FNM_DIR/aliases/default/bin"
  "$NPM_USER_PREFIX/bin"
)

RC_BEGIN="# >>> server-toolkit >>>"
RC_END="# <<< server-toolkit <<<"

# Supaya tool yang baru dipasang langsung bisa dipakai di sesi ini.
path_refresh_session() {
  local d
  for d in "${USER_BIN_DIRS[@]}"; do
    case ":$PATH:" in *":$d:"*) ;; *) PATH="$d:$PATH" ;; esac
  done
  export PATH
  hash -r 2>/dev/null || true
}

path_persist() {
  local block rc tmp
  block="$RC_BEGIN
# Ditulis oleh server-toolkit/setup.sh. Aman dihapus bersama penanda di atas dan bawah.
export FNM_DIR=\"$FNM_DIR\"
for d in ${USER_BIN_DIRS[*]}; do
  case \":\$PATH:\" in *\":\$d:\"*) ;; *) PATH=\"\$d:\$PATH\" ;; esac
done
export PATH
$RC_END"
  for rc in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile"; do
    # .zshrc hanya disentuh kalau zsh ada (default di macOS)
    if [ "$rc" = "$HOME/.zshrc" ] && ! has_cmd zsh; then continue; fi
    [ "$DRY_RUN" = 1 ] && { printf '  [dry-run] perbarui PATH di %s\n' "$rc"; continue; }
    touch "$rc"
    tmp="$(mktemp)"
    awk -v b="$RC_BEGIN" -v e="$RC_END" '$0==b{skip=1} !skip{print} $0==e{skip=0}' "$rc" >"$tmp"
    printf '\n%s\n' "$block" >>"$tmp"
    cat "$tmp" >"$rc" && rm -f "$tmp"
  done
  _log_file INFO "blok PATH diperbarui di rc shell"
}

# Unduh skrip installer resmi ke file sementara lalu jalankan.
# Lebih aman dari "curl | bash": kalau unduhan putus, skrip setengah jadi tidak ikut jalan.
#   run_remote_script <url> <bash|sh|root:sh> [argumen installer...]
# Awalan "root:" menjalankan installer sebagai root (untuk get.docker.com).
run_remote_script() {
  if [ "$DRY_RUN" = 1 ]; then
    printf '  [dry-run] unduh %s lalu jalankan dengan %s\n' "$1" "${*:2}"
    return 0
  fi
  # Installer sendiri juga mengunduh biner, jadi seluruh proses yang diulang.
  retry 3 _run_remote_script_once "$@"
}

_run_remote_script_once() {
  local url="$1" shell="$2" tmp runner=()
  shift 2
  case "$shell" in
    root:*) shell="${shell#root:}"; [ "$SUDO" = sudo ] && runner=(sudo) ;;
  esac
  tmp="$(mktemp)"
  if has_cmd curl; then
    curl -fsSL --retry 3 "$url" -o "$tmp" >>"$LOG_FILE" 2>&1
  else
    wget -qO "$tmp" "$url" >>"$LOG_FILE" 2>&1
  fi || { rm -f "$tmp"; error "Gagal mengunduh $url"; return 1; }
  _log_file CMD "$shell $url $*"
  # Bentuk ${arr[@]+...} supaya array kosong aman di bash 3.2 dengan set -u
  ${runner[@]+"${runner[@]}"} "$shell" "$tmp" "$@" >>"$LOG_FILE" 2>&1
  local rc=$?
  rm -f "$tmp"
  return $rc
}

# npm global tanpa sudo. Node dari fnm sudah per-user; node sistem (mis. Alpine)
# diarahkan ke ~/.npm-global agar tidak perlu root.
npm_global_install() {
  if [ "$DRY_RUN" = 1 ]; then run npm install -g "$@"; return; fi
  if ! has_cmd npm; then error "npm belum ada. Pasang tool 'node' dulu."; return 1; fi
  local prefix
  prefix="$(npm config get prefix 2>/dev/null)"
  if [ ! -w "$prefix" ] && [ "$DRY_RUN" != 1 ]; then
    mkdir -p "$NPM_USER_PREFIX"
    npm config set prefix "$NPM_USER_PREFIX" >>"$LOG_FILE" 2>&1
  fi
  retry 3 run npm install -g "$@"
}

# Versi mayor node yang terpasang, 0 kalau tidak ada.
node_major() {
  has_cmd node || { echo 0; return; }
  node -v 2>/dev/null | sed -E 's/^v([0-9]+).*/\1/'
}
