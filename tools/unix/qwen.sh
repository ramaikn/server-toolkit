# Qwen Code. Cara pasang resmi lewat npm global (butuh tool node).
# Kuota gratis Qwen OAuth berakhir 15 April 2026; model dipakai lewat OpenRouter atau API key.

qwen_check()   { has_cmd qwen; }
qwen_version() { echo "qwen $(qwen --version 2>/dev/null)"; }
qwen_install() { tool_require node && npm_global_install @qwen-code/qwen-code@latest; }
qwen_hint()    { echo "Qwen Code: jalankan 'qwen' lalu atur provider (OpenRouter atau API key)."; }
