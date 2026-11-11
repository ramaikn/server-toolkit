# Claude Code lewat installer native resmi, ke ~/.local/bin. Update otomatis.

claude_check()   { has_cmd claude; }
claude_version() { claude --version 2>/dev/null; }
claude_install() { run_remote_script https://claude.ai/install.sh bash; }
claude_hint()    { echo "Claude Code: jalankan 'claude' lalu login (butuh langganan Claude atau API key)."; }
