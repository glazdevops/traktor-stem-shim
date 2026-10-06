#!/bin/sh

set -eu

usage() {
    cat <<'EOF'
Usage: download_stem_track.sh [--output-dir DIR] [--title TITLE] URL

Download/extract one URL as a high-quality MP3, add a custom ID3 "label" tag
with the value "stem", and move it into DIR. Also append "stem" to the ID3
publisher metadata for compatibility while preserving existing publisher text.
If --title is supplied, set the MP3 title tag as well.
Default output directory: /Users/$(whoami)/Music/traktor_import

Install by running `sh install.sh` from the project folder.

Requires yt-dlp, ffmpeg, and ffprobe on PATH.
EOF
}

fail() {
    printf 'Error: %s\n' "$*" >&2
    exit 1
}

strip_query_params_except_v() {
    printf '%s\n' "$1" | awk '
    {
        url = $0
        fragment = ""
        hash = index(url, "#")
        if (hash) {
            fragment = substr(url, hash)
            url = substr(url, 1, hash - 1)
        }

        question = index(url, "?")
        if (!question) {
            print url fragment
            next
        }

        base = substr(url, 1, question - 1)
        query = substr(url, question + 1)
        count = split(query, params, "&")
        kept = ""
        for (i = 1; i <= count; i++) {
            equals = index(params[i], "=")
            key = equals ? substr(params[i], 1, equals - 1) : params[i]
            if (key == "v") {
                kept = kept (kept == "" ? "" : "&") params[i]
            }
        }

        print base (kept == "" ? "" : "?" kept) fragment
    }'
}

output_dir="/Users/$(whoami)/Music/traktor_import"
title=
url=

while [ "$#" -gt 0 ]; do
    case "$1" in
        -o|--output-dir)
            [ "$#" -ge 2 ] || fail "Missing value for $1"
            output_dir=$2
            shift 2
            ;;
        --title)
            [ "$#" -ge 2 ] || fail "Missing value for --title"
            title=$2
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        --)
            shift
            [ "$#" -eq 1 ] || fail "Expected one URL"
            url=$1
            shift
            ;;
        -* )
            fail "Unknown option: $1"
            ;;
        *)
            [ -z "$url" ] || fail "Expected one URL"
            url=$1
            shift
            ;;
    esac
done

[ -n "$url" ] || fail "Specify a URL"
url=$(strip_query_params_except_v "$url")

for command_name in yt-dlp ffmpeg ffprobe; do
    command -v "$command_name" >/dev/null 2>&1 || fail "Required command not found: $command_name"
done

mkdir -p "$output_dir"
output_dir=$(cd "$output_dir" && pwd -P)
work_dir=$(mktemp -d "${TMPDIR:-/tmp}/traktor-stem.XXXXXX")
cleanup() {
    rm -rf "$work_dir"
}
trap cleanup EXIT
trap 'exit 1' HUP INT TERM

downloaded_path=$(yt-dlp \
    --no-playlist \
    --no-progress \
    --quiet \
    --no-simulate \
    --print after_move:filepath \
    --output "$work_dir/%(title)s.%(ext)s" \
    -x \
    --audio-format mp3 \
    --audio-quality 0 \
    --embed-metadata \
    -- "$url")

[ -f "$downloaded_path" ] || fail "yt-dlp did not produce a file at the reported path"

publisher=$(ffprobe \
    -v error \
    -show_entries format_tags=publisher \
    -of default=noprint_wrappers=1:nokey=1 \
    "$downloaded_path")

case "$publisher" in
    *[Ss][Tt][Ee][Mm]*)
        tagged_publisher=$publisher
        ;;
    '')
        tagged_publisher=stem
        ;;
    *)
        tagged_publisher="$publisher; stem"
        ;;
esac

tagged_path="$work_dir/tagged.mp3"
if [ -n "$title" ]; then
    ffmpeg -hide_banner -loglevel error -y \
        -i "$downloaded_path" \
        -map 0 -c copy -map_metadata 0 \
        -id3v2_version 3 \
        -metadata "label=stem" \
        -metadata "publisher=$tagged_publisher" \
        -metadata "title=$title" \
        -f mp3 "$tagged_path"
else
    ffmpeg -hide_banner -loglevel error -y \
        -i "$downloaded_path" \
        -map 0 -c copy -map_metadata 0 \
        -id3v2_version 3 \
        -metadata "label=stem" \
        -metadata "publisher=$tagged_publisher" \
        -f mp3 "$tagged_path"
fi

filename=$(basename "$downloaded_path")
destination="$output_dir/$filename"
[ ! -e "$destination" ] || fail "Destination already exists: $destination"
mv "$tagged_path" "$destination"

printf 'Downloaded and tagged: %s\n' "$destination"
printf 'ID3 label: stem\n'
printf 'ID3 publisher: %s\n' "$tagged_publisher"