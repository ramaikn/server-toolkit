# OpenCode CLI lewat installer resmi v2, ke ~/.opencode/bin.
# PATH diurus blok server-toolkit, jadi installer tidak perlu mengubah rc shell.

opencode_check()   { has_cmd opencode; }
opencode_version() { echo "opencode $(opencode --version 2>/dev/null)"; }
opencode_install() { run_remote_script https://opencode.ai/v2/install bash --no-modify-path; }
opencode_hint()    { echo "OpenCode: jalankan 'opencode' di folder proyek, lalu '/connect' untuk memilih model gratis."; }
