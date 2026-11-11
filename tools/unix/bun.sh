# Bun lewat installer resmi, ke ~/.bun (per-user).

bun_check()   { has_cmd bun; }
bun_version() { echo "bun $(bun --version 2>/dev/null)"; }
bun_install() { run_remote_script https://bun.sh/install bash; }
