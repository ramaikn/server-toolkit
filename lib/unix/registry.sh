# Membaca config/profiles.conf dan menjalankan tool.
#
# Kontrak file tools/unix/<nama>.sh (id = nama dengan '-' diganti '_'):
#   <id>_check      wajib. return 0 jika sudah terpasang dan siap pakai.
#   <id>_install    wajib. memasang tool, return 0 jika berhasil.
#   <id>_supported  opsional. return 1 + cetak alasan jika tidak cocok untuk platform ini.
#   <id>_version    opsional. cetak versi singkat untuk ringkasan.
#   <id>_hint       opsional. cetak langkah lanjutan untuk user (login, dll).

PROFILES_CONF="$TOOLKIT_ROOT/config/profiles.conf"

# Cetak "kunci<TAB>nilai" dari satu bagian [section].
_conf_section() {
  awk -v want="[$1]" '
    /^[[:space:]]*#/ || /^[[:space:]]*$/ { next }
    /^\[/ { sec=$0; next }
    sec==want {
      i=index($0,"="); if (!i) next
      k=substr($0,1,i-1); v=substr($0,i+1)
      gsub(/^[ \t]+|[ \t]+$/,"",k); gsub(/^[ \t]+|[ \t]+$/,"",v)
      print k "\t" v
    }' "$PROFILES_CONF" | tr -d '\r'
}

conf_all_tools()     { _conf_section tools | cut -f1; }
conf_tool_desc()     { _conf_section tools | awk -F'\t' -v k="$1" '$1==k{print $2}'; }
conf_profile()       { _conf_section profiles | awk -F'\t' -v k="$1" '$1==k{print $2}'; }
conf_profile_names() { _conf_section profiles | cut -f1 | tr '\n' ' '; }

tool_id()   { echo "${1//-/_}"; }
fn_exists() { declare -F "$1" >/dev/null; }

tool_load() {
  local file="$TOOLKIT_ROOT/tools/unix/$1.sh"
  [ -f "$file" ] || { error "Implementasi tool '$1' tidak ditemukan ($file)."; return 1; }
  # shellcheck disable=SC1090
  source "$file"
}

# Hasil per tool untuk ringkasan akhir. Disimpan sebagai variabel RES_<id> dan
# NOTE_<id>, bukan associative array, karena bash bawaan macOS masih versi 3.2.
HINTS=()
set_result() { printf -v "RES_$(tool_id "$1")" '%s' "$2"; printf -v "NOTE_$(tool_id "$1")" '%s' "${3:-}"; }
get_result() { local v; v="RES_$(tool_id "$1")"; echo "${!v:-}"; }
get_note()   { local v; v="NOTE_$(tool_id "$1")"; echo "${!v:-}"; }
tool_version_text() {
  local id; id="$(tool_id "$1")"
  fn_exists "${id}_version" && "${id}_version" 2>/dev/null | head -n1
}

# Dipanggil dari <id>_install untuk memastikan tool lain sudah ada lebih dulu,
# misalnya gemini butuh node walau user hanya memilih --only gemini.
tool_require() {
  local dep="$1"
  [ -n "$(get_result "$dep")" ] || tool_process "$dep" install
  case "$(get_result "$dep")" in sudah|dipasang|rencana) return 0 ;; esac
  error "Butuh '$dep' yang gagal dipasang."
  return 1
}

# Status: sudah | dipasang | gagal | dilewati | belum (mode check)
tool_process() {
  local name="$1" mode="$2" id reason
  id="$(tool_id "$name")"
  tool_load "$name" || { set_result "$name" gagal "file tool tidak ada"; return; }

  if fn_exists "${id}_supported" && ! reason="$("${id}_supported")"; then
    set_result "$name" dilewati "$reason"
    info "$name: dilewati ($reason)"
    return
  fi

  if "${id}_check"; then
    set_result "$name" sudah "$(tool_version_text "$name")"
    ok "$name sudah terpasang $(get_note "$name")"
    return
  fi

  if [ "$mode" = check ]; then
    set_result "$name" belum
    warn "$name belum terpasang"
    return
  fi

  title "Memasang $name: $(conf_tool_desc "$name")"
  if "${id}_install"; then
    path_refresh_session
    if [ "$DRY_RUN" = 1 ]; then set_result "$name" rencana "akan dipasang"; return; fi
    if "${id}_check"; then
      set_result "$name" dipasang "$(tool_version_text "$name")"
      ok "$name siap $(get_note "$name")"
      if fn_exists "${id}_hint"; then HINTS+=("$("${id}_hint")"); fi
      return
    fi
  fi
  set_result "$name" gagal "lihat log"
  error "$name gagal dipasang. Detail di $LOG_FILE"
}
