#!/usr/bin/env bash
# Backup database n8n (PostgreSQL) plus salinan .env (berisi kunci enkripsi n8n).
# Hasil: $INSTALL_DIR/backups/n8n-db-TANGGAL.sql.gz dan env-TANGGAL.bak (izin 600).
# Backup lama dihapus otomatis, hanya yang namanya cocok pola di atas dan yang melebihi
# BACKUP_KEEP terbaru (bawaan 7; isi 0 untuk tidak menghapus apa pun).
#
# Pemakaian:  sudo bash backup.sh
# Cron harian (jam 02:00):  0 2 * * * cd /lokasi/server-toolkit && bash backup.sh >/dev/null 2>&1

set -euo pipefail
# shellcheck source=lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

BACKUP_DIR="${BACKUP_DIR:-$INSTALL_DIR/backups}"
BACKUP_KEEP="${BACKUP_KEEP:-7}"

dump_database() {
  local target="$1"
  cd "$INSTALL_DIR"
  if ! docker compose exec -T db pg_dump -U n8n --no-owner n8n | gzip >"$target"; then
    rm -f "$target"
    die "pg_dump gagal. Backup dibatalkan."
  fi
  # File harus utuh dan tidak kosong, kalau tidak backup ini tidak berguna.
  gzip -t "$target" || { rm -f "$target"; die "File backup rusak, dibatalkan."; }
  [ "$(stat -c %s "$target")" -gt 200 ] || { rm -f "$target"; die "File backup terlalu kecil, dibatalkan."; }
}

# Simpan hanya BACKUP_KEEP terbaru untuk satu pola nama.
rotate() {
  local pattern="$1"
  [ "$BACKUP_KEEP" -gt 0 ] || return 0
  # shellcheck disable=SC2012
  ls -1t "$BACKUP_DIR"/$pattern 2>/dev/null | tail -n +$((BACKUP_KEEP + 1)) | xargs -r rm -f
}

main() {
  require_stack
  umask 077
  mkdir -p "$BACKUP_DIR"
  local stamp dump
  stamp="$(date +%Y%m%d-%H%M%S)"
  dump="$BACKUP_DIR/n8n-db-$stamp.sql.gz"

  info "Backup database ke $dump"
  dump_database "$dump"
  cp "$INSTALL_DIR/.env" "$BACKUP_DIR/env-$stamp.bak"

  rotate 'n8n-db-*.sql.gz'
  rotate 'env-*.bak'
  info "Backup selesai ($(du -h "$dump" | cut -f1)). Simpan salinan di tempat lain juga (komputer lain atau cloud)."
}

main "$@"
