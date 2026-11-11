# uv (installer resmi Astral, ke ~/.local/bin) lalu Python 3.12 yang dikelola uv.
# Python sistem tidak disentuh.

PYTHON_VERSION=3.12

python_check() { has_cmd uv && uv python find "$PYTHON_VERSION" >/dev/null 2>&1; }

python_version() {
  local py
  py="$(uv python find "$PYTHON_VERSION" 2>/dev/null)"
  echo "$(uv --version 2>/dev/null), $("$py" --version 2>/dev/null)"
}

python_install() {
  if ! has_cmd uv; then
    # UV_NO_MODIFY_PATH: PATH sudah diurus blok server-toolkit
    UV_NO_MODIFY_PATH=1 run_remote_script https://astral.sh/uv/install.sh sh || return 1
    path_refresh_session
  fi
  run uv python install "$PYTHON_VERSION"
}
