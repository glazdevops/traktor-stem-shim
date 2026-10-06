#!/bin/sh

set -eu

fail() {
    printf 'Error: %s\n' "$*" >&2
    exit 1
}

script_dir=$(CDPATH= cd "$(dirname "$0")" && pwd -P)
downloader="$script_dir/download_stem_track.sh"
[ -f "$downloader" ] || fail "Downloader not found beside install.sh: $downloader"

command -v brew >/dev/null 2>&1 || fail "Homebrew is required to install yt-dlp and ffmpeg."
brew install yt-dlp ffmpeg

launcher_dir="$HOME/bin"
launcher="$launcher_dir/download-stem-track"
mkdir -p "$launcher_dir" "$HOME/Music/traktor_import"
chmod +x "$downloader"

if [ -L "$launcher" ]; then
    rm "$launcher"
elif [ -e "$launcher" ]; then
    fail "Refusing to replace existing non-symlink: $launcher"
fi
ln -s "$downloader" "$launcher"

zshrc="$HOME/.zshrc"
path_line='export PATH="$HOME/bin:$PATH"'
if ! grep -qxF "$path_line" "$zshrc" 2>/dev/null; then
    printf '\n%s\n' "$path_line" >> "$zshrc"
fi

printf 'Installed %s\n' "$launcher"
printf 'Open a new zsh terminal or run: source "%s"\n' "$zshrc"