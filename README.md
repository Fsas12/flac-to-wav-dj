![FLAC to WAV for DJs](assets/banner.png)

# FLAC → WAV for DJs

A small, free Windows utility for batch-converting a folder of FLAC tracks to PCM WAV with FFmpeg.

**Folder in. WAVs out. Get back to preparing your set.**

[Русская инструкция](README.ru.md) · [Support the project](#support)

## Quick start

1. [Download v1.0.0](https://github.com/Fsas12/flac-to-wav-dj/releases/download/v1.0.0/flac-to-wav-dj-v1.0.0.zip) and extract the ZIP.
2. Install [FFmpeg](https://ffmpeg.org/download.html). On that page, choose a Windows build. Copy **ffmpeg.exe** from its bin folder next to the two converter scripts, or add that bin folder to PATH.
3. Put your FLAC tracks beside **convert_flac_to_wav.bat** and **Convert-FlacToWav.ps1**. Keep both script files together.
4. Double-click **convert_flac_to_wav.bat**.
5. Find the results in the **wav** folder. The window reports converted, skipped and failed files.

Requires Windows 10/11 with Windows PowerShell 5.1 or newer and a separately installed FFmpeg. No administrator rights are required to run the converter. The BAT launcher uses a process-scoped execution-policy override to run its companion script; it does not change the system policy. Managed computer policies may still prevent it from running.

## What it does

- Converts the first audio stream of each .flac file to integer PCM WAV.
- Leaves original FLAC files untouched.
- Skips existing output files; it never overwrites them.
- Writes a temporary WAV, then moves it into place only when FFmpeg succeeds.
- Continues after a damaged file and writes a timestamped CSV log.
- Handles spaces, Cyrillic names, brackets and punctuation in filenames.
- Optionally scans subfolders, preserving their relative paths.
- Runs locally. The scripts do not upload audio, collect telemetry or make network requests.

## Audio settings

Default: **16-bit PCM**, original sample rate and channel count. For 24-bit source audio, the default reduces bit depth; choose 24-bit if you want to keep that precision. Raising bit depth does not restore information absent from the source. The script does not normalize, limit, downmix or change BPM.

WAV compatibility depends on the specific player and its supported sample rates, bit depths and channel counts. Check your device manual. Tags are copied where the WAV container supports them; artwork and all DJ/library metadata are not guaranteed to survive. WAVs usually occupy more disk space than FLACs. This tool does not prepare USB-drive formats or analyze tracks in DJ software.

## Use an existing music folder

Run in PowerShell from the extracted project directory:

~~~powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Convert-FlacToWav.ps1 -InputDirectory "D:\Music\Set"
~~~

The output defaults to a wav subfolder of the input folder.

~~~powershell
# Scan subfolders and keep 24-bit precision
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Convert-FlacToWav.ps1 -InputDirectory "D:\Music\Set" -Recurse -BitDepth 24

# Choose a different output folder and explicitly request 44.1 kHz
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Convert-FlacToWav.ps1 -InputDirectory "D:\Music\Set" -OutputDirectory "D:\Music\WAV" -SampleRate 44100
~~~

Available options: InputDirectory, OutputDirectory, Recurse, BitDepth (16 or 24), SampleRate (0 = original, 44100, 48000), FFmpegPath (explicit path to ffmpeg.exe).

Exit codes: **0** = all converted/skipped or no files; **1** = at least one file failed; **2** = setup error. Logs contain local file paths: review them before sharing in an issue.

## Troubleshooting

**FFmpeg not found:** put ffmpeg.exe beside the scripts or restart your terminal after updating PATH.

**No files found:** the default scans only the script folder. Choose InputDirectory, or use Recurse for subfolders.

**Skipped:** an output with that name already exists. Choose another OutputDirectory to reconvert safely.

**Failed:** inspect the CSV error field. Try playing or validating the source FLAC. A failed conversion does not replace an existing WAV.

## Support

<!-- donation:start -->
If this utility saves you time, you can support its development with a voluntary crypto donation.

| Network | Accepted assets | Receive address |
| --- | --- | --- |
| **Solana** | USDC, USDT, SOL | `Hmm7KwiuEUUN58SxwPx8i5NGQnEwQqw3YEAzzwDnvk91` |
| **Tron (TRC20)** | USDT | `TBBczfJbPkGaqyVt8Gw1VyGhewef5feyy7` |

[Donation instructions and QR codes](SUPPORT.md)

Select the exact network shown above in your sending wallet or exchange.
<!-- donation:end -->

## Contributing

Issues and small pull requests are welcome. Include your Windows version, FFmpeg version, chosen options and a redacted error message. Use synthetic test audio; do not upload copyrighted tracks or your music library.

## License and credits

The scripts and documentation are released under the [MIT License](LICENSE). FFmpeg is a separate project with its own license; its binary is not distributed here. This utility is not affiliated with a DJ equipment manufacturer.
