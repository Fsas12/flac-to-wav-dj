# FLAC → WAV for DJs

Need WAV copies of your FLAC tracks for your DJ setup? Batch-convert the FLAC files in a folder on Windows and find the results in a separate `wav` folder.

**[Download the BAT version for Windows — ZIP](https://github.com/Fsas12/flac-to-wav-dj/archive/refs/heads/main.zip)** · [Русская инструкция](README.ru.md)

Free to use. Original FLAC files stay untouched, and audio is processed on your computer.

**Requirements:** Windows 10/11 and FFmpeg downloaded separately. This BAT version does not require a companion PowerShell script.

**About v1.0.0:** the release is a different, PowerShell-based version. A launch problem has been reported with that version. The download above contains the simple BAT version currently recommended here.

## Quick start

1. Download and extract the ZIP linked above. Open the extracted project folder containing `convert_flac_to_wav.bat`.
2. Set up FFmpeg. On 64-bit Windows, open [Gyan's Windows builds](https://www.gyan.dev/ffmpeg/builds/), download `ffmpeg-release-essentials.zip`, and extract it. Copy `ffmpeg.exe` from its `bin` folder into the folder containing the BAT file. If FFmpeg is already available through PATH, skip this step.
3. For a first try, copy 1–2 FLAC tracks directly into that same folder. Subfolders are not scanned.
4. Double-click `convert_flac_to_wav.bat`. FFmpeg's progress and any errors appear in the window.
5. Open the `wav` folder beside the BAT file. Play the resulting WAVs and check them in your DJ software or player before processing the rest of your selection.

**If a WAV with the same name already exists, FFmpeg may ask to overwrite it. Choose `N` to keep it, or use a fresh project folder for another conversion. This BAT does not automatically skip existing WAVs.**

[Need help?](#troubleshooting) · [Report a problem](https://github.com/Fsas12/flac-to-wav-dj/issues/new)

![FLAC to WAV for DJs](assets/banner.png)

## What this BAT does

- Runs FFmpeg for each `.flac` file directly in the current folder.
- Saves WAV files with matching base names in a `wav` subfolder.
- Leaves the source FLAC files untouched.
- Displays FFmpeg's console output and keeps the window open at the end.
- Processes audio locally; the BAT contains no upload or telemetry commands.

This simple launcher has no settings interface, recursive scanning, automatic safe-skip mode, CSV log, or converted/skipped/failed summary.

## Audio settings and compatibility

The BAT uses FFmpeg's default WAV conversion settings. FFmpeg's default WAV audio encoder is 16-bit PCM; this launcher does not offer a 24-bit mode or selectable sample rate. Do not assume that a 24-bit FLAC retains its original bit depth.

Compatibility depends on your player's supported bit depths, sample rates and channel counts. Check the resulting files on the intended device. Preservation of artwork and all DJ/library metadata is not guaranteed, and WAV files usually occupy more disk space than FLACs.

The utility does not format USB drives or analyze tracks in DJ software.

## Troubleshooting

**FFmpeg is not recognized:** put `ffmpeg.exe` in the extracted project folder and launch the BAT from that folder. Alternatively, add FFmpeg's `bin` folder to PATH and open a new terminal before trying again.

**No FLAC files are converted:** place the FLAC files directly beside the BAT. Files inside subfolders are not scanned.

**FFmpeg asks to overwrite a file:** choose `N` to keep the existing WAV. For a fresh conversion, use another project folder.

**An error appears or a WAV does not play:** read the FFmpeg message in the window and check whether the source FLAC plays. This BAT does not validate completed outputs or produce a CSV error log; inspect the resulting files before using them for a set.

**You downloaded v1.0.0:** that release uses a different PowerShell implementation. For the simple BAT workflow documented here, use the ZIP linked at the top of this page.

## Support

<!-- donation:start -->
This utility is free to use. If it saves you time, you can support its development with a voluntary crypto donation.

| Network | Accepted assets | Receive address |
| --- | --- | --- |
| **Solana** | USDC, USDT, SOL | `Hmm7KwiuEUUN58SxwPx8i5NGQnEwQqw3YEAzzwDnvk91` |
| **Tron (TRC20)** | USDT | `TBBczfJbPkGaqyVt8Gw1VyGhewef5feyy7` |

[Donation instructions and QR codes](SUPPORT.md)

Select the exact network shown above in your sending wallet or exchange.
<!-- donation:end -->

## Contributing

[Report a problem](https://github.com/Fsas12/flac-to-wav-dj/issues/new) with your Windows version, FFmpeg version, the download you used (BAT version or v1.0.0), and the error text without personal information. Do not upload your music library; use synthetic test audio for examples.

Small pull requests are welcome.

## License and credits

The scripts and documentation are released under the [MIT License](LICENSE). FFmpeg is a separate project with its own license; its binary is not distributed here. This utility is not affiliated with a DJ equipment manufacturer.
