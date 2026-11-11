#!/usr/bin/env bash
# Memulihkan database n8n dari file backup. MENGGANTI seluruh isi database saat ini.
# Sebelum menimpa, skrip membuat backup pengaman otomatis lewat backup.sh.
#
# Pemakaian:
#   sudo bash restore.sh                       lihat daftar backup yang ada
#   sudo bash restore.sh /path/n8n-db-XXX.sql.gz   pulihkan dari file itu

set -euo pipefail
# shellcheck source=lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

BACKUP_DIR="${BACKUP_DIR:-$INSTALL_DIR/backups}"

list_backups() {
  echo "Backup yang tersedia di $BACKUP_DIR:"
  ls -1t "$BACKUP_DIR"/n8n-db-*.sql.gz 2>/dev/null || echo "  (belum ada)"
  echo
  echo "Pakai: sudo bash restore.sh <file-backup>"
}

confirm_overwrite() {
  local file="$1" typed
  echo "PERINGATAN: seluruh data n8n saat ini (alur, kredensial, riwayat) akan DIGANTI"
  echo "dengan isi $file."
  read -r -p "Ketik RESTORE (huruf besar) untuk lanjut: " typed || true
  [ "$typed" = "RESTORE" ] || die "Dibatalkan, tidak ada yang diubah."
}

apply_restore() {
  local file="$1"
  cd "$INSTALL_DIR"
  info "Menghentikan n8n sementara."
  docker compose stop n8n
  info "Mengosongkan database dan memuat backup."
  docker compose exec -T db psql -U n8n -d n8n -v ON_ERROR_STOP=1 -q \
    -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"
  gunzip -c "$file" | docker compose exec -T db psql -U n8n -d n8n -v ON_ERROR_STOP=1 -q
  info "Menjalankan n8n lagi."
  docker compose start n8n
}

main() {
  if [ $# -eq 0 ]; then
    list_backups
    exit 0
  fi
  local file="$1"
  [ -f "$file" ] || die "File tidak ditemukan: $file"
  gzip -t "$file" || die "File backup rusak: $file"
  require_stack
  confirm_overwrite "$file"

  info "Membuat backup pengaman dulu."
  bash "$TOOLKIT_ROOT/backup.sh"

  if ! apply_restore "$file"; then
    die "Restore gagal di tengah jalan. Database mungkin kosong. Backup pengaman ada di $BACKUP_DIR, pulihkan dari file terbaru di sana."
  fi
  info "Restore selesai. Cek: cd $INSTALL_DIR && docker compose ps"
}

main "$@"
