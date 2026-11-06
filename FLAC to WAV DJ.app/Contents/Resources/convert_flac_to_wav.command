#!/bin/bash
# macOS /bin/bash 3.2 compatible. No audio is uploaded or source files changed.
set -u

temp_file=''
scan_file=''
cleanup() {
    if [ -n "$temp_file" ] && [ -f "$temp_file" ]; then
        rm -f -- "$temp_file"
    fi
    if [ -n "$scan_file" ] && [ -f "$scan_file" ]; then
        rm -f -- "$scan_file"
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
    printf 'Usage: %s [folder-with-FLAC-or-AIFF-files]\n' "$0" >&2
    finish 2
fi
if ! source_dir=$(cd -- "${1:-$script_dir}" && pwd -P); then
    printf 'ERROR: Cannot open the input folder.\n' >&2
    finish 2
fi

source_prefix="${source_dir%/}/"
output_dir="${source_prefix}wav"
if ! scan_file=$(mktemp "${TMPDIR:-/tmp}/flac-to-wav-scan.XXXXXX"); then
    printf 'ERROR: Cannot create a temporary file list.\n' >&2
    finish 2
fi
# NUL-delimited paths preserve spaces, newlines and non-Latin names. The output
# tree is excluded, and find does not follow directory or file symlinks.
if ! (cd -- "$source_dir" && find . -ipath './wav' -prune -o -type f \
    \( -iname '*.flac' -o -iname '*.aif' -o -iname '*.aiff' \) -print0) > "$scan_file"; then
    printf 'ERROR: Could not scan all input folders. Check folder permissions.\n' >&2
    finish 2
fi
input_files=()
while IFS= read -r -d '' source; do
    input_files+=("$source_prefix${source#./}")
done < "$scan_file"
rm -f -- "$scan_file"
scan_file=''
if [ "${#input_files[@]}" -eq 0 ]; then
    printf 'No FLAC or AIFF files found in this folder or its subfolders:\n%s\n' "$source_dir"
    finish 0
fi

# Finder does not necessarily load the same PATH as an interactive Terminal.
requested_engine=${FLAC_TO_WAV_ENGINE:-auto}
case "$requested_engine" in
    auto|ffmpeg|afconvert) ;;
    *) printf 'ERROR: Unknown audio engine.\n' >&2; finish 2 ;;
esac
ffmpeg=''
if [ "$requested_engine" = afconvert ]; then
    :
elif [ -f "$script_dir/ffmpeg" ] && [ -x "$script_dir/ffmpeg" ]; then
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
engine=ffmpeg
if [ "$requested_engine" = afconvert ] || { [ -z "$ffmpeg" ] && [ "$requested_engine" = auto ] && [ -x /usr/bin/afconvert ]; }; then
    engine=afconvert
    if [ ! -x /usr/bin/afconvert ]; then
        printf 'ERROR: The built-in macOS audio converter is unavailable.\n' >&2
        finish 2
    fi
elif [ -z "$ffmpeg" ]; then
    printf 'FFmpeg not found. / FFmpeg не найден.\n\n'
    printf 'Install it once with Homebrew in Terminal:\n  brew install ffmpeg\n\n'
    printf 'No Homebrew yet? Follow https://brew.sh first.\n'
    printf 'You can also put a macOS ffmpeg executable beside this .command file.\n'
    finish 2
fi

if ! mkdir -p -- "$output_dir"; then
    printf 'ERROR: Cannot create the wav folder. Check write permissions and free space.\n' >&2
    finish 2
fi

converted=0
skipped=0
failed=0
index=0
printf 'FLAC / AIFF -> WAV | 16-bit PCM | %s files\nInput: %s\n\n' "${#input_files[@]}" "$source_dir"
printf 'Engine: %s\n' "$engine"
convert_audio() {
    if [ "$engine" = afconvert ]; then
        /usr/bin/afconvert -f WAVE -d LEI16 "$1" "$2"
    else
        "$ffmpeg" -hide_banner -nostdin -loglevel error -y -i "$1" \
            -map 0:a:0 -vn -map_metadata 0 -c:a pcm_s16le -f wav "$2"
    fi
}
for source in "${input_files[@]}"; do
    index=$((index + 1))
    filename=${source##*/}
    relative=${source#"$source_prefix"}
    target="$output_dir/${relative%.*}.wav"
    if [ -e "$target" ] || [ -L "$target" ]; then
        printf '[%s/%s] SKIP (already exists): %s\n' "$index" "${#input_files[@]}" "$relative"
        skipped=$((skipped + 1))
        continue
    fi

    printf '[%s/%s] CONVERT: %s\n' "$index" "${#input_files[@]}" "$relative"
    target_dir=${target%/*}
    if ! mkdir -p -- "$target_dir"; then
        printf 'ERROR: Cannot create output folder for %s\n' "$relative" >&2
        failed=$((failed + 1))
        continue
    fi
    if ! temp_file=$(mktemp "$target_dir/.flac-to-wav.XXXXXX"); then
        printf 'ERROR: Cannot create a temporary file in the wav folder.\n' >&2
        finish 2
    fi
    # -y applies only to our private mktemp file, never to an existing WAV.
    if convert_audio "$source" "$temp_file" && [ -s "$temp_file" ]; then
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
