#!/usr/bin/env bash
# Cek kesehatan server dalam 1 menit. Hanya MEMBACA, tidak mengubah apa pun.
# Pemakaian:  bash health-check.sh   (pakai sudo agar kolom Process di port terisi)

set -uo pipefail
# shellcheck source=lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

DISK_WARN_PERCENT=90

section() { printf '\n== %s ==\n' "$1"; }

check_uptime() {
  section "1. Waktu menyala dan beban"
  uptime
}

check_disk() {
  section "2. Disk (waspada jika di atas ${DISK_WARN_PERCENT}%)"
  df -h /
  local used
  used="$(df --output=pcent / | tail -1 | tr -dc '0-9')"
  if [ -n "$used" ] && [ "$used" -ge "$DISK_WARN_PERCENT" ]; then
    warn "Disk terpakai ${used}%. Cari penyebabnya: du -sh /* 2>/dev/null | sort -h | tail"
  fi
}

check_memory() {
  section "3. Memori (lihat kolom available)"
  free -m
}

check_docker() {
  section "4. Container Docker"
  if ! command -v docker >/dev/null; then
    echo "Docker tidak terpasang di server ini."
  elif ! docker ps >/dev/null 2>&1; then
    echo "Tidak bisa menjalankan docker ps (izin kurang? coba dengan sudo)."
  else
    docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
  fi
}

check_ports() {
  section "5. Port yang terbuka"
  ss -tulpn
}

main() {
  info "health-check dimulai"
  check_uptime
  check_disk
  check_memory
  check_docker
  check_ports
  echo
  info "health-check selesai"
}

main "$@"
