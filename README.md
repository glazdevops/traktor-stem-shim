# Traktor Stem Shim

A small macOS shell utility that downloads an MP3 from an authorized YouTube source, adds a `stem` metadata marker, and places the finished file in a Traktor import folder. Traktor stem generation is still started manually with the mapped `Ctrl+G` shortcut.

## Use Only Authorized Downloads

Use this utility only for audio you own or are explicitly allowed to download, such as your own uploads, public-domain works, or content whose license/creator expressly permits downloading. Free to stream or watch does not necessarily mean free to download. Follow the creator's license and YouTube's terms.

## Install

Requires `yt-dlp`, `ffmpeg`, and `ffprobe`:

- [`yt-dlp`](https://github.com/yt-dlp/yt-dlp)
- [`FFmpeg`](https://github.com/FFmpeg/FFmpeg)
- [`ffprobe` source](https://github.com/FFmpeg/FFmpeg/blob/master/fftools/ffprobe.c) (included with FFmpeg)

```sh
sh install.sh
source "$HOME/.zshrc"
command -v download-stem-track
```

## Usage

```sh
download-stem-track "YOUTUBE_URL"
download-stem-track --title "Preferred Track Title" "YOUTUBE_URL"
download-stem-track --output-dir "$HOME/Music/Traktor Inbox" "YOUTUBE_URL"
```

The default destination is `$HOME/Music/traktor_import`. A YouTube watch URL is reduced to its `v` parameter, dropping other query parameters such as playlist and timestamp values. The utility downloads one item, converts it to high-quality MP3, preserves existing publisher metadata, adds the custom ID3 `label=stem` marker, and refuses to overwrite a file already in the destination.

## Traktor Setup

1. In Traktor's File Management preferences, add `$HOME/Music/traktor_import` to **Music Folders**. Use the **Import Music Folders** action, or bind the action you found to an unused keyboard shortcut such as `Ctrl+F` if Controller Manager offers it. Confirm the new track appears in the collection without restarting Traktor.
[File Management Settings](img/traktor-file-management-settings.png)
2. Create or use a smart playlist with the rule `Label contains stem`.
3. Confirm the imported track's Label actually contains `stem`. The script writes a custom ID3 label field, but Traktor's import of that field has not yet been verified. If the Label is blank, set it in Traktor and add the track to the collection; the smart playlist depends on the collection's Label value.
4. Select one or more matching tracks and press your mapped `Ctrl+G` shortcut to queue **Generate Stems**. The downloader does not trigger Traktor or report stem-processing completion.

The script only downloads, tags, and stages the file. It does not rescan Traktor's folders, edit Traktor's collection database, or invoke keyboard shortcuts.
