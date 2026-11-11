# OpenCode Desktop. macOS lewat Homebrew cask. Linux dilewati karena server umumnya
# tanpa layar; Windows ditangani setup.ps1.

opencode_desktop_supported() {
  [ "$OS_KIND" = macos ] && return 0
  echo "aplikasi desktop hanya dipasang di Windows dan macOS"
  return 1
}
opencode_desktop_check()   { [ -d "/Applications/OpenCode.app" ] || brew list --cask opencode-desktop >/dev/null 2>&1; }
opencode_desktop_install() { run brew install --cask opencode-desktop; }
