#!/usr/bin/env bash
# Memasang n8n + PostgreSQL dengan Docker di server Ubuntu/Debian.
# Aman dijalankan ulang: tidak menghapus data, dan menanyakan dulu sebelum memakai ulang .env.
#
# Pemakaian:  sudo bash install.sh
# Opsi lewat variabel lingkungan (semua boleh kosong):
#   INSTALL_DIR=/opt/n8n-stack   lokasi pemasangan
#   POSTGRES_PASSWORD=...        lewati prompt password

set -euo pipefail
# shellcheck source=lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

ENV_FILE="$INSTALL_DIR/.env"

require_root_and_apt() {
  [ "$(id -u)" -eq 0 ] || die "Jalankan dengan sudo: sudo bash install.sh"
  command -v apt-get >/dev/null || die "Skrip ini untuk Ubuntu/Debian (butuh apt-get)."
}

# Docker dan Compose dipasang terpisah, lalu diverifikasi. Dilewati kalau sudah ada.
ensure_docker() {
  if command -v docker >/dev/null && docker compose version >/dev/null 2>&1; then
    info "Docker dan Compose sudah terpasang, dilewati."
    return
  fi
  info "Memasang Docker dan Compose (bisa 1 sampai 3 menit)."
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -y >>"$LOG_FILE" 2>&1
  apt-get install -y docker.io >>"$LOG_FILE" 2>&1
  apt-get install -y docker-compose-v2 >>"$LOG_FILE" 2>&1
  docker --version >/dev/null 2>&1 || die "Docker gagal terpasang. Lihat $LOG_FILE"
  docker compose version >/dev/null 2>&1 || die "Docker Compose gagal terpasang. Lihat $LOG_FILE"
  systemctl enable --now docker >>"$LOG_FILE" 2>&1 || true
  info "Docker dan Compose siap."
}

# Password dibatasi huruf, angka, titik, garis bawah, dan strip supaya aman di file .env.
read_password() {
  if [ -n "${POSTGRES_PASSWORD:-}" ]; then
    echo "$POSTGRES_PASSWORD"
    return
  fi
  local p1 p2
  while true; do
    read -r -s -p "Password database (kosongkan untuk dibuatkan acak): " p1; echo >&2
    if [ -z "$p1" ]; then
      openssl rand -hex 16
      return
    fi
    read -r -s -p "Ulangi password: " p2; echo >&2
    if [ "$p1" != "$p2" ]; then
      warn "Dua password berbeda, coba lagi." >&2
    elif [[ ! "$p1" =~ ^[A-Za-z0-9._-]{8,}$ ]]; then
      warn "Password minimal 8 karakter, hanya huruf, angka, titik, garis bawah, strip." >&2
    else
      echo "$p1"
      return
    fi
  done
}

write_env_file() {
  local password timezone bind
  password="$(read_password)"
  timezone="$(ask_value 'Zona waktu' 'Asia/Makassar')"
  bind="$(ask_value 'Alamat buka n8n (127.0.0.1 = hanya dari server itu sendiri, 0.0.0.0 = dari jaringan)' '127.0.0.1')"
  umask 077
  cat >"$ENV_FILE" <<EOF
POSTGRES_PASSWORD=$password
N8N_ENCRYPTION_KEY=$(openssl rand -hex 24)
TZ=$timezone
N8N_BIND_ADDRESS=$bind
N8N_PORT=5678
EOF
  if ask_yes_no "Pasang gateway WhatsApp WAHA? (tidak resmi, nomor bisa diblokir WhatsApp)" n; then
    cat >>"$ENV_FILE" <<EOF
COMPOSE_PROFILES=waha
WAHA_BIND_ADDRESS=127.0.0.1
WAHA_PORT=3000
WAHA_API_KEY=$(openssl rand -hex 16)
WAHA_DASHBOARD_PASSWORD=$(openssl rand -hex 8)
EOF
    info "WAHA diaktifkan. Kunci API dan password dashboard ada di $ENV_FILE (baca dengan sudo)."
  fi
  chmod 600 "$ENV_FILE"
  info ".env dibuat di $ENV_FILE (izin 600, hanya root yang bisa membaca)."
}

prepare_install_dir() {
  mkdir -p "$INSTALL_DIR"
  cp "$TOOLKIT_ROOT/templates/compose.yaml" "$INSTALL_DIR/compose.yaml"
  if [ -f "$ENV_FILE" ] && ask_yes_no ".env sudah ada. Pakai ulang (disarankan, supaya password dan kunci enkripsi tidak berubah)?" y; then
    info "Memakai .env yang ada."
  else
    write_env_file
  fi
}

start_stack() {
  cd "$INSTALL_DIR"
  docker compose config --quiet || die "compose.yaml atau .env tidak valid."
  info "Menjalankan layanan (unduhan pertama bisa beberapa menit)."
  docker compose up -d
}

# n8n menyediakan /healthz. Tunggu sampai menjawab, maksimal 120 detik.
wait_for_n8n() {
  local port
  port="$(grep -E '^N8N_PORT=' "$ENV_FILE" | cut -d= -f2)"
  info "Menunggu n8n siap di port ${port:-5678}."
  for _ in $(seq 1 24); do
    if curl -fsS "http://127.0.0.1:${port:-5678}/healthz" >/dev/null 2>&1; then
      info "n8n siap."
      return 0
    fi
    sleep 5
  done
  warn "n8n belum menjawab. Cek: cd $INSTALL_DIR && docker compose ps && docker compose logs --tail 50 n8n"
  return 1
}

main() {
  require_root_and_apt
  ensure_docker
  prepare_install_dir
  start_stack
  wait_for_n8n || true
  docker compose ps
  info "Selesai. Buka n8n di http://127.0.0.1:5678 (dari komputermu: ssh -L 5678:localhost:5678 user@ip)."
}

main "$@"
