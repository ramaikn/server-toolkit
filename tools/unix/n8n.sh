# n8n + PostgreSQL di Docker. Stack dari stacks/n8n disalin ke ~/n8n-stack,
# .env berisi password dan kunci acak dibuat sekali lalu dipakai ulang.
# Tidak pernah menghapus volume atau data.

N8N_DIR="${N8N_DIR:-$HOME/n8n-stack}"
N8N_PORT_DEFAULT=5678

# Pakai sudo kalau user belum masuk grup docker (baru dipasang, belum login ulang).
_n8n_docker() {
  if docker info >/dev/null 2>&1 || [ "$SUDO" != sudo ]; then docker "$@"; else sudo docker "$@"; fi
}

_n8n_port() {
  local p
  p="$(grep -E '^N8N_PORT=' "$N8N_DIR/.env" 2>/dev/null | cut -d= -f2)"
  echo "${p:-$N8N_PORT_DEFAULT}"
}

n8n_check()  { curl -fsS "http://127.0.0.1:$(_n8n_port)/healthz" >/dev/null 2>&1; }
n8n_version() { echo "http://127.0.0.1:$(_n8n_port)"; }

_random_hex() { od -An -N"$1" -tx1 /dev/urandom | tr -d ' \n'; }

_n8n_write_env() {
  local tz
  tz="$(readlink /etc/localtime 2>/dev/null | sed -E 's#.*/zoneinfo/##')"
  (
    umask 077
    {
      echo "# Dibuat otomatis oleh setup.sh. Simpan salinan file ini: tanpa N8N_ENCRYPTION_KEY,"
      echo "# kredensial di n8n tidak bisa dibuka setelah dipulihkan."
      echo "POSTGRES_PASSWORD=$(_random_hex 16)"
      echo "N8N_ENCRYPTION_KEY=$(_random_hex 24)"
      echo "TZ=${tz:-UTC}"
      echo "N8N_BIND_ADDRESS=127.0.0.1"
      echo "N8N_PORT=$N8N_PORT_DEFAULT"
    } >"$N8N_DIR/.env"
  )
  info ".env baru dibuat di $N8N_DIR/.env (izin 600)."
}

n8n_install() {
  tool_require docker || return 1
  if [ "$DRY_RUN" = 1 ]; then
    info "[dry-run] salin stacks/n8n ke $N8N_DIR, buat .env bila belum ada, docker compose up -d"
    return 0
  fi
  mkdir -p "$N8N_DIR"
  cp "$TOOLKIT_ROOT/stacks/n8n/compose.yaml" "$N8N_DIR/compose.yaml"
  if [ -f "$N8N_DIR/.env" ]; then
    info "Memakai .env yang sudah ada (password dan kunci tidak berubah)."
  else
    _n8n_write_env
  fi

  info "Menjalankan n8n (unduhan pertama bisa beberapa menit)."
  ( cd "$N8N_DIR" && _n8n_docker compose up -d ) >>"$LOG_FILE" 2>&1 || return 1

  local _
  for _ in $(seq 1 24); do
    n8n_check && return 0
    sleep 5
  done
  error "n8n belum menjawab setelah 2 menit. Cek: cd $N8N_DIR && docker compose logs --tail 50 n8n"
  return 1
}

n8n_hint() {
  echo "n8n: buka http://127.0.0.1:$(_n8n_port). Dari laptop lain: ssh -L 5678:localhost:5678 user@ip-server"
}
