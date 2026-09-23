#!/usr/bin/env bash
set -euo pipefail

TARGET_USER=${SUDO_USER:-$USER}
TARGET_HOME=$(getent passwd "$TARGET_USER" | cut -d: -f6)
APT_READY=0
APT_DIRTY=1
declare -A DECISIONS=()
INSTALLED_APPS=()
SKIPPED_APPS=()
FAILED_APPS=()
ALREADY_PRESENT=()

if (( EUID == 0 )) && [[ -z ${SUDO_USER:-} ]]; then
  printf 'Please run this script as your regular user, not directly as root.\n' >&2
  exit 1
fi

if ! command -v sudo >/dev/null 2>&1; then
  printf 'sudo is required.\n' >&2
  exit 1
fi

if ! command -v apt-get >/dev/null 2>&1; then
  printf 'This script requires apt/apt-get.\n' >&2
  exit 1
fi

source /etc/os-release
if [[ ${ID:-} != ubuntu && ${ID_LIKE:-} != *ubuntu* && ${ID_LIKE:-} != *debian* ]]; then
  printf 'This script targets Ubuntu-based distributions.\n' >&2
  exit 1
fi

note() { printf '\n[%s] %s\n' "$1" "$2"; }
mark_installed() { INSTALLED_APPS+=("$1"); }
mark_skipped() { SKIPPED_APPS+=("$1"); }
mark_failed() { FAILED_APPS+=("$1"); }
mark_present() { ALREADY_PRESENT+=("$1"); }

run_as_root() {
  sudo "$@"
}

run_as_user() {
  sudo -u "$TARGET_USER" env HOME="$TARGET_HOME" "$@"
}

confirm() {
  local reply
  read -rp "$1 [y/N]: " reply
  [[ $reply =~ ^[Yy]$ ]]
}

choose_app() {
  local id=$1 label=$2 reason=${3:-}
  if [[ ${DECISIONS[$id]:-} == yes ]]; then
    return 0
  fi

  if [[ -n $reason ]]; then
    confirm "$label is required for $reason. Install it?" || {
      DECISIONS[$id]=no
      return 1
    }
  else
    confirm "Install $label?" || {
      DECISIONS[$id]=no
      return 1
    }
  fi

  DECISIONS[$id]=yes
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

package_installed() {
  dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q 'ok installed'
}

snap_installed() {
  command_exists snap && snap list "$1" >/dev/null 2>&1
}

flatpak_installed() {
  command_exists flatpak && flatpak info "$1" >/dev/null 2>&1
}

apt_update() {
  if (( APT_READY == 0 || APT_DIRTY == 1 )); then
    note INFO 'Updating apt package metadata...'
    run_as_root apt-get update
    APT_READY=1
    APT_DIRTY=0
  fi
}

apt_install() {
  apt_update
  run_as_root apt-get install -y "$@"
}

add_apt_repo() {
  "$@"
  APT_DIRTY=1
}

ensure_support_packages() {
  local package
  for package in "$@"; do
    package_installed "$package" || apt_install "$package"
  done
}

ensure_snap() {
  if command_exists snap; then
    run_as_root systemctl enable --now snapd.socket || true
    return 0
  fi
  choose_app snap 'snap' "$1" || return 1
  note INFO 'Installing snap support...'
  apt_install snapd
  run_as_root systemctl enable --now snapd.socket || true
  mark_installed 'snap'
}

ensure_flatpak() {
  if command_exists flatpak; then
    run_as_root flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    return 0
  fi
  choose_app flatpak 'Flatpak' "$1" || return 1
  note INFO 'Installing Flatpak support...'
  apt_install flatpak
  run_as_root flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
  mark_installed 'Flatpak'
}

install_snap_choice() {
  if command_exists snap; then
    note SKIP 'snap is already installed.'
    mark_present 'snap'
    return 0
  fi
  choose_app snap 'snap' || {
    note SKIP 'Skipping snap.'
    mark_skipped 'snap'
    return 0
  }
  note INFO 'Installing snap support...'
  apt_install snapd
  run_as_root systemctl enable --now snapd.socket || true
  mark_installed 'snap'
}

install_flatpak_choice() {
  if command_exists flatpak; then
    note SKIP 'Flatpak is already installed.'
    mark_present 'Flatpak'
    run_as_root flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    return 0
  fi
  choose_app flatpak 'Flatpak' || {
    note SKIP 'Skipping Flatpak.'
    mark_skipped 'Flatpak'
    return 0
  }
  note INFO 'Installing Flatpak support...'
  apt_install flatpak
  run_as_root flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
  mark_installed 'Flatpak'
}

install_apt_choice() {
  local id=$1 label=$2 package=$3 check=${4:-$3}
  if package_installed "$package" || command_exists "$check"; then
    note SKIP "$label is already installed."
    mark_present "$label"
    return 0
  fi
  choose_app "$id" "$label" || {
    note SKIP "Skipping $label."
    mark_skipped "$label"
    return 0
  }
  note INFO "Installing $label..."
  if apt_install "$package"; then
    mark_installed "$label"
  else
    note ERROR "Failed to install $label."
    mark_failed "$label"
    return 1
  fi
}

install_neovim() {
  local label='Neovim' tmpdir archive
  if command_exists nvim; then
    note SKIP "$label is already installed."
    mark_present "$label"
    return 0
  fi
  choose_app neovim "$label" || {
    note SKIP "Skipping $label."
    mark_skipped "$label"
    return 0
  }
  note INFO 'Installing Neovim from the official prebuilt archive...'
  ensure_support_packages wget tar
  tmpdir=$(mktemp -d)
  archive="$tmpdir/nvim-linux-x86_64.tar.gz"
  wget -O "$archive" https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
  run_as_root rm -rf /opt/nvim-linux-x86_64
  run_as_root tar -C /opt -xzf "$archive"
  run_as_root ln -sf /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim
  rm -rf "$tmpdir"
  mark_installed "$label"
}

install_pdftk() {
  local label='pdftk'
  if command_exists pdftk; then
    note SKIP "$label is already installed."
    mark_present "$label"
    return 0
  fi
  choose_app pdftk "$label" || {
    note SKIP "Skipping $label."
    mark_skipped "$label"
    return 0
  }
  note INFO 'Installing pdftk...'
  if package_installed pdftk || apt-cache show pdftk >/dev/null 2>&1; then
    apt_install pdftk
  else
    apt_install pdftk-java
  fi || {
    note ERROR 'Failed to install pdftk.'
    mark_failed "$label"
    return 1
  }
  mark_installed "$label"
}

install_wezterm() {
  local label='WezTerm'
  if command_exists wezterm; then
    note SKIP "$label is already installed."
    mark_present "$label"
    return 0
  fi
  choose_app wezterm "$label" || {
    note SKIP "Skipping $label."
    mark_skipped "$label"
    return 0
  }
  note INFO 'Installing WezTerm...'
  ensure_support_packages ca-certificates wget gpg
  if [[ ! -f /usr/share/keyrings/wezterm-fury.gpg ]]; then
    add_apt_repo bash -lc 'wget -qO- https://apt.fury.io/wez/gpg.key | sudo gpg --yes --dearmor -o /usr/share/keyrings/wezterm-fury.gpg'
    run_as_root chmod 644 /usr/share/keyrings/wezterm-fury.gpg
  fi
  if [[ ! -f /etc/apt/sources.list.d/wezterm.list ]]; then
    add_apt_repo bash -lc "echo 'deb [signed-by=/usr/share/keyrings/wezterm-fury.gpg] https://apt.fury.io/wez/ * *' | sudo tee /etc/apt/sources.list.d/wezterm.list >/dev/null"
  fi
  if apt_install wezterm; then
    mark_installed "$label"
  else
    note ERROR "Failed to install $label."
    mark_failed "$label"
    return 1
  fi
}

install_signal() {
  local label='Signal Desktop' tmpdir
  if command_exists signal-desktop; then
    note SKIP "$label is already installed."
    mark_present "$label"
    return 0
  fi
  choose_app signal "$label" || {
    note SKIP "Skipping $label."
    mark_skipped "$label"
    return 0
  }
  note INFO 'Installing Signal Desktop...'
  ensure_support_packages ca-certificates wget gpg
  tmpdir=$(mktemp -d)
  wget -qO- https://updates.signal.org/desktop/apt/keys.asc | gpg --dearmor > "$tmpdir/signal-desktop-keyring.gpg"
  wget -qO "$tmpdir/signal-desktop.sources" https://updates.signal.org/static/desktop/apt/signal-desktop.sources
  add_apt_repo run_as_root install -m 0644 "$tmpdir/signal-desktop-keyring.gpg" /usr/share/keyrings/signal-desktop-keyring.gpg
  add_apt_repo run_as_root install -m 0644 "$tmpdir/signal-desktop.sources" /etc/apt/sources.list.d/signal-desktop.sources
  if apt_install signal-desktop; then
    rm -rf "$tmpdir"
    mark_installed "$label"
  else
    rm -rf "$tmpdir"
    note ERROR "Failed to install $label."
    mark_failed "$label"
    return 1
  fi
}

install_flatpak_app() {
  local id=$1 label=$2 ref=$3
  if flatpak_installed "$ref"; then
    note SKIP "$label is already installed."
    mark_present "$label"
    return 0
  fi
  choose_app "$id" "$label" || {
    note SKIP "Skipping $label."
    mark_skipped "$label"
    return 0
  }
  ensure_flatpak "$label" || {
    note SKIP "Skipping $label because Flatpak support is unavailable."
    mark_skipped "$label"
    return 0
  }
  note INFO "Installing $label..."
  if run_as_root flatpak install -y flathub "$ref"; then
    mark_installed "$label"
  else
    note ERROR "Failed to install $label."
    mark_failed "$label"
    return 1
  fi
}

install_pied() {
  local label='Pied'
  if snap_installed pied || flatpak_installed com.mikeasoft.pied; then
    note SKIP "$label is already installed."
    mark_present "$label"
    return 0
  fi
  choose_app pied "$label" || {
    note SKIP "Skipping $label."
    mark_skipped "$label"
    return 0
  }
  ensure_snap "$label" || {
    note SKIP "Skipping $label because snap support is unavailable."
    mark_skipped "$label"
    return 0
  }
  if ! package_installed espeak-ng && ! command_exists espeak-ng; then
    choose_app espeak-ng 'espeak-ng' "$label" || {
      note SKIP "Skipping $label because espeak-ng was declined."
      mark_skipped "$label"
      return 0
    }
    install_apt_choice espeak-ng 'espeak-ng' espeak-ng espeak-ng || return 1
  fi
  ensure_support_packages speech-dispatcher qml-module-qtmultimedia qt6-speech-speechd-plugin
  note INFO 'Installing Pied from the official Snap package...'
  if run_as_root snap install pied; then
    mark_installed "$label"
  else
    note ERROR "Failed to install $label."
    mark_failed "$label"
    return 1
  fi
}

install_rust_neovim_setup() {
  local label='Rust toolchain + rust-analyzer for Neovim'
  if run_as_user bash -lc 'command -v rustup >/dev/null 2>&1 && command -v rust-analyzer >/dev/null 2>&1'; then
    note SKIP "$label is already installed."
    mark_present "$label"
    return 0
  fi
  choose_app rust-neovim "$label" || {
    note SKIP "Skipping $label."
    mark_skipped "$label"
    return 0
  }
  if ! command_exists nvim; then
    choose_app neovim 'Neovim' "$label" || {
      note SKIP "Skipping $label because Neovim was declined."
      mark_skipped "$label"
      return 0
    }
    install_neovim || return 1
  fi
  ensure_support_packages wget build-essential pkg-config libssl-dev
  note INFO 'Installing the Rust toolchain and rust-analyzer...'
  if ! run_as_user bash -lc 'command -v rustup >/dev/null 2>&1'; then
    wget -qO- https://sh.rustup.rs | run_as_user sh -s -- -y
  fi
  run_as_user bash -lc 'source "$HOME/.cargo/env" && rustup default stable && rustup component add rust-analyzer rust-src rustfmt'
  run_as_user bash -lc 'mkdir -p "$HOME/.config/nvim/plugin"'
  run_as_user bash -lc "cat > \"$TARGET_HOME/.config/nvim/plugin/rust_analyzer.lua\" <<'LUA'
local group = vim.api.nvim_create_augroup('RustAnalyzerSetup', { clear = true })

local function rust_root(bufnr)
  local name = vim.api.nvim_buf_get_name(bufnr)
  local dir = vim.fn.fnamemodify(name, ':p:h')
  local found = vim.fs.find({ 'Cargo.toml', 'rust-project.json', '.git' }, { path = dir, upward = true })[1]
  if found then
    return vim.fn.fnamemodify(found, ':h')
  end
  return dir
end

vim.api.nvim_create_autocmd('FileType', {
  group = group,
  pattern = 'rust',
  callback = function(args)
    if vim.fn.executable('rust-analyzer') == 0 then
      return
    end
    vim.lsp.start({
      name = 'rust-analyzer',
      cmd = { 'rust-analyzer' },
      root_dir = rust_root(args.buf),
    })
  end,
})
LUA"
  mark_installed "$label"
}

install_docker_desktop() {
  local label='Docker Desktop' tmpdir deb_file codename arch
  if package_installed docker-desktop; then
    note SKIP "$label is already installed."
    mark_present "$label"
    return 0
  fi
  choose_app docker-desktop "$label" || {
    note SKIP "Skipping $label."
    mark_skipped "$label"
    return 0
  }
  note INFO 'Installing Docker Desktop...'
  ensure_support_packages ca-certificates wget gpg gnome-terminal
  run_as_root install -m 0755 -d /etc/apt/keyrings
  if [[ ! -f /etc/apt/keyrings/docker.asc ]]; then
    add_apt_repo run_as_root wget -qO /etc/apt/keyrings/docker.asc https://download.docker.com/linux/ubuntu/gpg
    run_as_root chmod a+r /etc/apt/keyrings/docker.asc
  fi
  codename=${UBUNTU_CODENAME:-$VERSION_CODENAME}
  arch=$(dpkg --print-architecture)
  if [[ ! -f /etc/apt/sources.list.d/docker.list ]]; then
    add_apt_repo bash -lc "echo 'deb [arch=${arch} signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu ${codename} stable' | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null"
  fi
  apt_update
  tmpdir=$(mktemp -d)
  deb_file="$tmpdir/docker-desktop-amd64.deb"
  wget -O "$deb_file" https://desktop.docker.com/linux/main/amd64/docker-desktop-amd64.deb
  if run_as_root apt-get install -y "$deb_file"; then
    rm -rf "$tmpdir"
    mark_installed "$label"
  else
    rm -rf "$tmpdir"
    note ERROR "Failed to install $label."
    mark_failed "$label"
    return 1
  fi
}

install_virtualbox() {
  local label='VirtualBox' version tmpdir extpack_file actual_user
  if command_exists VBoxManage; then
    note SKIP "$label is already installed."
    mark_present "$label"
    return 0
  fi
  choose_app virtualbox "$label" || {
    note SKIP "Skipping $label."
    mark_skipped "$label"
    return 0
  }
  note INFO 'Installing VirtualBox...'
  ensure_support_packages wget gpg dkms
  if [[ ! -f /usr/share/keyrings/oracle-virtualbox-2016.gpg ]]; then
    add_apt_repo bash -lc 'wget -O- https://www.virtualbox.org/download/oracle_vbox_2016.asc | sudo gpg --yes --dearmor --output /usr/share/keyrings/oracle-virtualbox-2016.gpg'
  fi
  if [[ ! -f /etc/apt/sources.list.d/virtualbox.list ]]; then
    add_apt_repo bash -lc "echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/oracle-virtualbox-2016.gpg] https://download.virtualbox.org/virtualbox/debian ${VERSION_CODENAME} contrib' | sudo tee /etc/apt/sources.list.d/virtualbox.list >/dev/null"
  fi
  if apt_install virtualbox-7.2; then
    actual_user=${SUDO_USER:-$USER}
    run_as_root usermod -aG vboxusers "$actual_user" || true
    mark_installed "$label"
  else
    note ERROR "Failed to install $label."
    mark_failed "$label"
    return 1
  fi

  if ! confirm 'Install the Oracle VirtualBox Extension Pack too?'; then
    note SKIP 'Skipping the VirtualBox Extension Pack.'
    mark_skipped 'VirtualBox Extension Pack'
    return 0
  fi

  version=$(VBoxManage -v | sed 's/r.*//')
  tmpdir=$(mktemp -d)
  extpack_file="$tmpdir/Oracle_VirtualBox_Extension_Pack-${version}.vbox-extpack"
  wget -O "$extpack_file" "https://download.virtualbox.org/virtualbox/${version}/Oracle_VirtualBox_Extension_Pack-${version}.vbox-extpack"
  if yes | run_as_root VBoxManage extpack install --replace "$extpack_file"; then
    rm -rf "$tmpdir"
    mark_installed 'VirtualBox Extension Pack'
  else
    rm -rf "$tmpdir"
    note ERROR 'Failed to install the VirtualBox Extension Pack.'
    mark_failed 'VirtualBox Extension Pack'
    return 1
  fi
}

main() {
  cat <<BANNER

Ubuntu application installer
============================
- Prompts before each requested application install
- Skips declined applications unless they are later required by something else you approve
- Includes the Flatpak apps listed in Seths_flatpaks.sh

BANNER

  install_apt_choice curl 'curl' curl curl || true
  install_apt_choice inxi 'inxi' inxi inxi || true
  install_apt_choice iwd 'iwd' iwd iwd || true
  install_apt_choice git 'git' git git || true
  install_apt_choice dmidecode 'dmidecode' dmidecode dmidecode || true
  install_apt_choice youtube-dl 'youtube-dl' youtube-dl youtube-dl || true
  install_apt_choice traceroute 'traceroute' traceroute traceroute || true
  install_pdftk || true
  install_apt_choice pdfshuffler 'pdfshuffler' pdfshuffler pdfshuffler || true
  install_apt_choice ffmpeg 'ffmpeg' ffmpeg ffmpeg || true
  install_apt_choice pandoc 'pandoc' pandoc pandoc || true
  install_apt_choice lsscsi 'lsscsi' lsscsi lsscsi || true
  install_snap_choice || true
  install_flatpak_choice || true
  install_neovim || true
  install_wezterm || true
  install_apt_choice espeak-ng 'espeak-ng' espeak-ng espeak-ng || true
  install_pied || true
  install_apt_choice clang 'LLVM clang compiler' clang clang || true
  install_apt_choice lld 'LLVM linker (lld)' lld ld.lld || true
  install_rust_neovim_setup || true
  install_signal || true
  install_flatpak_app vlc 'VLC' org.videolan.VLC || true
  install_flatpak_app shortwave 'Shortwave' de.haeckerfelix.Shortwave || true
  install_flatpak_app obsidian 'Obsidian' md.obsidian.Obsidian || true
  install_flatpak_app gimp 'GIMP' org.gimp.GIMP || true
  install_flatpak_app thunderbird 'Thunderbird' org.mozilla.Thunderbird || true
  install_flatpak_app bitwarden 'Bitwarden' com.bitwarden.desktop || true
  install_flatpak_app warehouse 'Warehouse' io.github.flattool.Warehouse || true
  install_flatpak_app newsflash 'NewsFlash' io.gitlab.news_flash.NewsFlash || true
  install_flatpak_app kiwix 'Kiwix' org.kiwix.desktop || true
  install_flatpak_app stellarium 'Stellarium' org.stellarium.Stellarium || true
  install_flatpak_app obs-studio 'OBS Studio' com.obsproject.Studio || true
  install_flatpak_app shotcut 'Shotcut' org.shotcut.Shotcut || true
  install_docker_desktop || true
  install_virtualbox || true

  printf '\nSummary\n=======\n'
  ((${#INSTALLED_APPS[@]})) && printf 'Installed: %s\n' "$(printf '%s, ' "${INSTALLED_APPS[@]}" | sed 's/, $//')"
  ((${#ALREADY_PRESENT[@]})) && printf 'Already present: %s\n' "$(printf '%s, ' "${ALREADY_PRESENT[@]}" | sed 's/, $//')"
  ((${#SKIPPED_APPS[@]})) && printf 'Skipped: %s\n' "$(printf '%s, ' "${SKIPPED_APPS[@]}" | sed 's/, $//')"
  ((${#FAILED_APPS[@]})) && printf 'Failed: %s\n' "$(printf '%s, ' "${FAILED_APPS[@]}" | sed 's/, $//')"

  printf '\nDone.\n'
}

main "$@"
