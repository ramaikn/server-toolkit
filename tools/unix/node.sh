# Node.js LTS lewat fnm, per-user tanpa sudo. Dibutuhkan Gemini CLI dan Qwen Code (Node 20+).
# PATH memakai folder alias "default" milik fnm, jadi node dan paket npm global
# bisa dipakai di shell mana pun tanpa "eval fnm env".

NODE_MIN_MAJOR=20

node_check()   { [ "$(node_major)" -ge "$NODE_MIN_MAJOR" ] && has_cmd npm; }
node_version() { echo "node $(node -v 2>/dev/null), npm $(npm -v 2>/dev/null)"; }

node_install() {
  # Biner Node resmi untuk glibc, tidak jalan di Alpine (musl). Pakai paket distro.
  if [ "$PKG_MGR" = apk ]; then
    pkg_install nodejs npm
    return
  fi
  if ! has_cmd fnm && [ ! -x "$FNM_DIR/fnm" ]; then
    run_remote_script https://fnm.vercel.app/install bash \
      --install-dir "$FNM_DIR" --skip-shell --force-install || return 1
  fi
  path_refresh_session
  if [ "$DRY_RUN" = 1 ]; then run fnm install --lts; return 0; fi

  # Ambil versi LTS terbaru secara eksplisit supaya alias default jelas.
  local v
  v="$(fnm ls-remote --lts 2>>"$LOG_FILE" | tail -n1 | awk '{print $1}')"
  [ -n "$v" ] || { error "Tidak bisa membaca daftar versi Node dari fnm."; return 1; }
  run fnm install "$v" && run fnm default "$v"
}
