#!/bin/bash
# macOS /bin/bash 3.2 compatible. No audio is uploaded or source files changed.
set -u

temp_file=''
cleanup() {
    if [ -n "$temp_file" ] && [ -f "$temp_file" ]; then
        rm -f -- "$temp_file"
    fi
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

finish() {
    result=$1
    if [ -t 0 ]; then
        printf '\nPress Return to close this window. / Нажми Enter, чтобы закрыть окно.\n'
        IFS= read -r answer || :
    fi
    exit "$result"
}

case "$0" in
    */*) script_dir=${0%/*} ;;
    *) script_dir=. ;;
esac
if ! script_dir=$(cd -- "$script_dir" && pwd -P); then
    printf 'ERROR: Cannot find the converter folder.\n' >&2
    finish 2
fi
if [ "$#" -gt 1 ]; then
    printf 'Usage: %s [folder-with-FLAC-files]\n' "$0" >&2
    finish 2
fi
if ! source_dir=$(cd -- "${1:-$script_dir}" && pwd -P); then
    printf 'ERROR: Cannot open the input folder.\n' >&2
    finish 2
fi

shopt -s nullglob nocaseglob
input_files=()
for source in "$source_dir"/*.flac; do
    if [ -f "$source" ]; then
        input_files+=("$source")
    fi
done
if [ "${#input_files[@]}" -eq 0 ]; then
    printf 'No FLAC files found in:\n%s\nPut FLAC files directly in this folder and try again.\n' "$source_dir"
    finish 0
fi

# Finder does not necessarily load the same PATH as an interactive Terminal.
ffmpeg=''
if [ -f "$script_dir/ffmpeg" ] && [ -x "$script_dir/ffmpeg" ]; then
    ffmpeg="$script_dir/ffmpeg"
elif command -v ffmpeg >/dev/null 2>&1; then
    ffmpeg=$(command -v ffmpeg)
else
    for candidate in /opt/homebrew/bin/ffmpeg /usr/local/bin/ffmpeg; do
        if [ -f "$candidate" ] && [ -x "$candidate" ]; then
            ffmpeg=$candidate
            break
        fi
    done
fi
if [ -z "$ffmpeg" ]; then
    printf 'FFmpeg not found. / FFmpeg не найден.\n\n'
    printf 'Install it once with Homebrew in Terminal:\n  brew install ffmpeg\n\n'
    printf 'No Homebrew yet? Follow https://brew.sh first.\n'
    printf 'You can also put a macOS ffmpeg executable beside this .command file.\n'
    finish 2
fi

output_dir="$source_dir/wav"
if ! mkdir -p -- "$output_dir"; then
    printf 'ERROR: Cannot create the wav folder. Check write permissions and free space.\n' >&2
    finish 2
fi

converted=0
skipped=0
failed=0
index=0
printf 'FLAC -> WAV | 16-bit PCM | %s files\nInput: %s\n\n' "${#input_files[@]}" "$source_dir"
for source in "${input_files[@]}"; do
    index=$((index + 1))
    filename=${source##*/}
    target="$output_dir/${filename%.*}.wav"
    if [ -e "$target" ] || [ -L "$target" ]; then
        printf '[%s/%s] SKIP (already exists): %s\n' "$index" "${#input_files[@]}" "$filename"
        skipped=$((skipped + 1))
        continue
    fi

    printf '[%s/%s] CONVERT: %s\n' "$index" "${#input_files[@]}" "$filename"
    if ! temp_file=$(mktemp "$output_dir/.flac-to-wav.XXXXXX"); then
        printf 'ERROR: Cannot create a temporary file in the wav folder.\n' >&2
        finish 2
    fi
    # -y applies only to our private mktemp file, never to an existing WAV.
    if "$ffmpeg" -hide_banner -nostdin -loglevel error -y -i "$source" \
        -map 0:a:0 -vn -map_metadata 0 -c:a pcm_s16le -f wav "$temp_file" && [ -s "$temp_file" ]; then
        # BSD mv -n also works on removable volumes without hard-link support.
        if mv -n -- "$temp_file" "$target"; then
            if [ -f "$temp_file" ]; then
                printf 'SKIP (output appeared during conversion): %s\n' "$filename"
                skipped=$((skipped + 1))
            else
                converted=$((converted + 1))
            fi
        elif [ -e "$target" ] || [ -L "$target" ]; then
            # Some mv implementations return nonzero when -n skips a new file.
            printf 'SKIP (output appeared during conversion): %s\n' "$filename"
            skipped=$((skipped + 1))
        else
            printf 'ERROR: Could not save %s\n' "$target" >&2
            failed=$((failed + 1))
        fi
    else
        printf 'ERROR: Could not convert %s; continuing with other files.\n' "$filename" >&2
        failed=$((failed + 1))
    fi
    cleanup
    temp_file=''
done

printf '\nDone. Converted: %s | Skipped: %s | Failed: %s\nOutput: %s\n' "$converted" "$skipped" "$failed" "$output_dir"
if [ "$failed" -gt 0 ]; then
    finish 1
fi
finish 0
