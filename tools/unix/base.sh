# Alat dasar yang dibutuhkan installer lain dan coding agent:
# git, curl, unzip (fnm/bun), tar, ca-certificates, build tools (modul native npm/pip),
# jq dan ripgrep (dipakai agent untuk mencari kode).

base_check() {
  has_cmd git && has_cmd curl && has_cmd unzip && has_cmd rg && has_cmd jq || return 1
  [ "$OS_KIND" != macos ] || has_cmd brew
}

base_version() { git --version 2>/dev/null; }

_base_install_homebrew() {
  has_cmd brew && return 0
  info "Memasang Homebrew (akan meminta password Mac)."
  NONINTERACTIVE=1 run_remote_script https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh bash || return 1
  # Lokasi brew beda antara Apple silicon dan Intel
  local b
  for b in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    if [ -x "$b" ]; then eval "$("$b" shellenv)"; break; fi
  done
  has_cmd brew || [ "$DRY_RUN" = 1 ]
}

base_install() {
  case "$PKG_MGR" in
    apt)
      pkg_install git curl wget unzip tar xz-utils ca-certificates gnupg build-essential jq ripgrep ;;
    dnf|yum)
      pkg_install git curl wget unzip tar xz ca-certificates gcc gcc-c++ make jq
      pkg_install_optional ripgrep ;;   # RHEL butuh EPEL untuk ripgrep
    pacman)
      pkg_install git curl wget unzip tar xz ca-certificates base-devel jq ripgrep ;;
    zypper)
      pkg_install git curl wget unzip tar xz ca-certificates gcc gcc-c++ make jq ripgrep ;;
    apk)
      # libgcc/libstdc++ dibutuhkan biner Claude Code di Alpine
      pkg_install bash git curl wget unzip tar xz ca-certificates build-base jq ripgrep libgcc libstdc++ ;;
    brew)
      _base_install_homebrew || return 1
      pkg_install git wget jq ripgrep ;;
    *)
      error "Package manager tidak dikenali. Pasang manual: git curl unzip jq ripgrep."
      return 1 ;;
  esac
}
