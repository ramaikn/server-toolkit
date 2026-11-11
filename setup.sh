#!/usr/bin/env bash
# Installer otomatis untuk Linux, macOS, dan WSL. Untuk Windows pakai setup.cmd.
#
#   ./setup.sh                      pasang profil "coding" (bawaan)
#   ./setup.sh --profile full       tambah Docker + n8n
#   ./setup.sh --interactive        pilih tool satu per satu
#   ./setup.sh --check              hanya cek yang sudah terpasang
#   ./setup.sh --help               semua opsi
#
# Aman dijalankan ulang: tool yang sudah ada dilewati. Jalankan sebagai user biasa;
# sudo diminta sendiri hanya untuk paket sistem dan Docker.

set -uo pipefail

TOOLKIT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export TOOLKIT_ROOT

# shellcheck source=lib/unix/log.sh
source "$TOOLKIT_ROOT/lib/unix/log.sh"
# shellcheck source=lib/unix/detect.sh
source "$TOOLKIT_ROOT/lib/unix/detect.sh"
# shellcheck source=lib/unix/pkg.sh
source "$TOOLKIT_ROOT/lib/unix/pkg.sh"
# shellcheck source=lib/unix/env.sh
source "$TOOLKIT_ROOT/lib/unix/env.sh"
# shellcheck source=lib/unix/registry.sh
source "$TOOLKIT_ROOT/lib/unix/registry.sh"

PROFILE=coding
ONLY=""
SKIP=""
INTERACTIVE=0
MODE=install
ASSUME_YES=0

usage() {
  cat <<EOF
Pemakaian: ./setup.sh [opsi]

  -p, --profile NAMA   profil: $(conf_profile_names)(bawaan: coding)
      --only a,b       pasang hanya tool ini (abaikan profil)
      --skip a,b       lewati tool ini
  -i, --interactive    pilih tool lewat menu
  -y, --yes            lewati konfirmasi di mode --interactive
      --dry-run        tampilkan rencana tanpa memasang apa pun
      --check          cek status tool saja
      --list           daftar tool dan profil
  -h, --help           bantuan ini
EOF
}

list_tools() {
  echo "Tool:"
  conf_all_tools | while read -r t; do printf '  %-17s %s\n' "$t" "$(conf_tool_desc "$t")"; done
  echo; echo "Profil:"
  for p in $(conf_profile_names); do printf '  %-8s %s\n' "$p" "$(conf_profile "$p")"; done
}

parse_args() {
  while [ $# -gt 0 ]; do
    case "$1" in
      -p|--profile)   PROFILE="${2:?nama profil kosong}"; shift ;;
      --only)         ONLY="${2:?daftar tool kosong}"; shift ;;
      --skip)         SKIP="${2:?daftar tool kosong}"; shift ;;
      -i|--interactive) INTERACTIVE=1 ;;
      -y|--yes)       ASSUME_YES=1 ;;
      --dry-run)      DRY_RUN=1 ;;
      --check)        MODE=check ;;
      --list)         list_tools; exit 0 ;;
      -h|--help)      usage; exit 0 ;;
      *)              usage; die "Opsi tidak dikenal: $1" ;;
    esac
    shift
  done
}

# Hasil: variabel SELECTED berisi nama tool berurutan, dipisah spasi.
resolve_tools() {
  local known t list
  known=" $(conf_all_tools | tr '\n' ' ') "
  if [ -n "$ONLY" ]; then
    list="${ONLY//,/ }"
  else
    list="$(conf_profile "$PROFILE")"
    [ -n "$list" ] || die "Profil '$PROFILE' tidak ada. Pilihan: $(conf_profile_names)"
  fi
  SELECTED=""
  for t in $list; do
    case "$known" in *" $t "*) ;; *) die "Tool '$t' tidak dikenal. Lihat ./setup.sh --list" ;; esac
    case ",$SKIP," in *",$t,"*) continue ;; esac
    SELECTED="$SELECTED $t"
  done
  SELECTED="${SELECTED# }"
}

# Menu sederhana: ketik nomor untuk mencentang/membatalkan, Enter untuk lanjut.
# Urutan tetap mengikuti config supaya dependensi terpasang lebih dulu.
interactive_menu() {
  local all=() t i input n
  while read -r t; do all+=("$t"); done < <(conf_all_tools)
  while true; do
    echo
    i=1
    for t in "${all[@]}"; do
      case " $SELECTED " in *" $t "*) mark="x" ;; *) mark=" " ;; esac
      printf '  %2d. [%s] %-17s %s\n' "$i" "$mark" "$t" "$(conf_tool_desc "$t")"
      i=$((i + 1))
    done
    read -r -p "  Nomor untuk mengubah pilihan (pisah spasi), Enter untuk lanjut: " input
    [ -z "$input" ] && break
    for n in $input; do
      [[ "$n" =~ ^[0-9]+$ ]] && [ "$n" -ge 1 ] && [ "$n" -le "${#all[@]}" ] || continue
      t="${all[$((n - 1))]}"
      case " $SELECTED " in
        *" $t "*) SELECTED="$(echo " $SELECTED " | sed "s/ $t / /" | xargs)" ;;
        *) SELECTED="$SELECTED $t" ;;
      esac
    done
    # Susun ulang mengikuti urutan config
    local ordered=""
    for t in "${all[@]}"; do case " $SELECTED " in *" $t "*) ordered="$ordered $t" ;; esac; done
    SELECTED="${ordered# }"
  done
}

# Minta password sudo sekali di awal, lalu jaga supaya tidak kedaluwarsa
# selama pemasangan panjang.
prime_sudo() {
  [ "$SUDO" = sudo ] || return 0
  [ "$DRY_RUN" = 1 ] && return 0
  case " $SELECTED " in *" base "*|*" docker "*) ;; *) return 0 ;; esac
  [ "$OS_KIND" = macos ] && return 0   # Homebrew meminta sendiri
  info "Beberapa langkah butuh sudo (paket sistem / Docker)."
  sudo -v || die "sudo dibatalkan."
  ( while kill -0 "$$" 2>/dev/null; do sudo -n true 2>/dev/null; sleep 50; done ) &
}

print_summary() {
  local t status failed=0 label
  title "Ringkasan"
  for t in $SELECTED; do
    status="$(get_result "$t")"
    case "$status" in
      sudah)    label="${C_GREEN}sudah ada${C_RESET}" ;;
      dipasang) label="${C_GREEN}dipasang${C_RESET} " ;;
      rencana)  label="${C_DIM}rencana${C_RESET}  " ;;
      dilewati) label="${C_DIM}dilewati${C_RESET} " ;;
      belum)    label="${C_YELLOW}belum${C_RESET}    " ;;
      *)        label="${C_RED}gagal${C_RESET}    "; failed=1 ;;
    esac
    printf '  %-17s %s  %s\n' "$t" "$label" "$(get_note "$t")"
  done
  if [ "${#HINTS[@]}" -gt 0 ]; then
    title "Langkah berikutnya"
    for t in "${HINTS[@]}"; do [ -n "$t" ] && printf '  - %s\n' "$t"; done
  fi
  if [ "$MODE" = install ] && [ "$DRY_RUN" != 1 ]; then
    printf '\n  Buka terminal baru (atau jalankan: exec $SHELL -l) supaya PATH baru terbaca.\n'
  fi
  printf '  Log lengkap: %s\n' "$LOG_FILE"
  return $failed
}

main() {
  parse_args "$@"
  if [ "$(id -u)" -eq 0 ] && [ -n "${SUDO_USER:-}" ]; then
    die "Jangan pakai sudo. Jalankan: ./setup.sh (sudo diminta sendiri bila perlu)."
  fi

  title "server-toolkit setup"
  detect_platform
  platform_summary
  [ "$(id -u)" -eq 0 ] && warn "Berjalan sebagai root: tool per-user dipasang di $HOME."
  path_refresh_session

  resolve_tools
  [ "$INTERACTIVE" = 1 ] && interactive_menu
  [ -n "$SELECTED" ] || die "Tidak ada tool yang dipilih."

  if [ "$MODE" = install ]; then
    printf '  Profil   : %s\n  Dipasang : %s\n' "$([ -n "$ONLY" ] && echo kustom || echo "$PROFILE")" "$SELECTED"
    [ "$DRY_RUN" = 1 ] && info "Mode dry-run: tidak ada yang dipasang."
    # Bawaan langsung jalan tanpa bertanya; konfirmasi hanya setelah memilih lewat menu.
    if [ "$INTERACTIVE" = 1 ]; then confirm "Lanjutkan?" y || die "Dibatalkan."; fi
    prime_sudo
  fi

  title "$([ "$MODE" = check ] && echo 'Memeriksa tool' || echo 'Memasang tool')"
  local t
  for t in $SELECTED; do tool_process "$t" "$MODE"; done

  [ "$MODE" = install ] && path_persist
  print_summary
}

main "$@"
