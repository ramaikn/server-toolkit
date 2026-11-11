# Gemini CLI. Cara pasang resmi lewat npm global (butuh tool node).

gemini_check()   { has_cmd gemini; }
gemini_version() { echo "gemini $(gemini --version 2>/dev/null)"; }
gemini_install() { tool_require node && npm_global_install @google/gemini-cli; }
gemini_hint()    { echo "Gemini CLI: jalankan 'gemini' lalu login dengan akun Google (kuota gratis harian)."; }
