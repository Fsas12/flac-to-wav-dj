# FLAC / AIFF → WAV for DJs

Convert a folder of FLAC and AIFF tracks to WAV on Windows or macOS. Original files stay untouched.

**[Download for Windows & macOS — ZIP](https://github.com/Fsas12/flac-to-wav-dj/archive/refs/heads/main.zip)** · [Русская инструкция](README.ru.md) · [macOS instructions](README.macOS.md)

## Quick start

### Windows: double-click, no commands to type

1. Extract the ZIP. Keep `convert_flac_to_wav.bat`, `Convert-AudioTree.ps1`, and `Install-FFmpeg.ps1` together.
2. Drag your Soulseek downloads folder onto `convert_flac_to_wav.bat`. All its subfolders are scanned automatically.
3. Alternatively, double-click the BAT to process the folder containing it, including its subfolders.
4. If FFmpeg is missing, click **Yes** in the setup dialog. The helper downloads a verified FFmpeg build once and continues automatically.
5. Find the WAVs in the selected folder's `wav` subfolder, with the same user/album structure.

The converter first checks for an existing FFmpeg beside the BAT, in PATH, or in its private user cache. The automatic download is a 64-bit Windows build, about 109 MB, and needs internet once. It is saved in `%LOCALAPPDATA%\FLAC-to-WAV-DJ\ffmpeg`. No administrator password or PATH editing is needed.

Existing output WAVs are skipped automatically. Re-run the converter after adding downloads: completed WAVs stay untouched.

### macOS: open the app

1. Extract the ZIP.
2. Double-click **FLAC to WAV DJ.app**.
3. Choose the folder containing your FLAC / AIFF tracks.
4. Use **Open WAV folder** when conversion finishes.

The app uses macOS's built-in audio converter: **no FFmpeg, Homebrew, installation command, or internet download is needed**. See [macOS help](README.macOS.md) for the first-open system prompt and the optional older `.command` launcher.

[Need help?](#troubleshooting) · [Report a problem](https://github.com/Fsas12/flac-to-wav-dj/issues/new)

![FLAC to WAV for DJs](assets/banner.png)

## Soulseek folders

Choose the root download folder once. Users and albums stay separate in the output:

| Source | Result |
| --- | --- |
| `Soulseek/User A/Album 1/01.flac` | `Soulseek/wav/User A/Album 1/01.wav` |
| `Soulseek/User B/Album 2/01.aiff` | `Soulseek/wav/User B/Album 2/01.wav` |

The root `wav` output tree is excluded from scanning. Folder/file symlinks and Windows junctions are not followed, preventing loops.

## What gets converted

- `.flac`, `.aif`, and `.aiff`, including uppercase extensions.
- Files in the selected folder and all its ordinary subfolders, on both platforms.
- WAVs with matching base names and relative folder paths, inside one root `wav` subfolder.
- Original audio stays on your computer. The Windows setup helper downloads software, never your tracks.

Both versions skip existing outputs, continue after a damaged file, and report converted/skipped/failed counts. Neither version creates CSV logs.

**Matching names:** `track.flac` and `track.aiff` share `wav/track.wav`. Within the same input folder, use distinct base names to keep both. Identically named tracks in different user/album folders remain separate.

## Audio settings and compatibility

Output is **16-bit PCM WAV**, with no explicit sample-rate or channel-count change. For 24-bit source audio this reduces bit depth. There is no 24-bit selector in these launchers.

Check the results in your intended DJ software or player before processing a whole library. Compatibility depends on your device's supported audio settings; preservation of artwork and all DJ/library metadata is not guaranteed. WAVs usually occupy more space than FLACs. The utility does not format USB drives or analyze tracks.

## Troubleshooting

**Windows setup cannot finish:** check internet access, free space, and permissions for your local user folder. Cancelled or checksum-failed downloads do not get installed. An error dialog explains the problem; rerun the BAT after fixing it. You can also put a trusted Windows `ffmpeg.exe` beside the BAT.

**Managed Windows computer:** organization policies may block Windows PowerShell, which is used by setup and recursive conversion. The launcher's process-scoped execution-policy override does not change system policy.

**Mac will not open the app:** follow [Apple's instructions for software you trust](https://support.apple.com/102445). The app is not signed or notarized with an Apple Developer ID. No global Gatekeeper setting needs changing.

**No files found:** select a folder containing supported audio, directly or in subfolders. Symlinks, junctions and the root `wav` output tree are excluded.

**A file fails:** check the original audio and free space. Mac continues with the other tracks; Windows displays FFmpeg's errors.

**About v1.0.0:** that older release uses a different PowerShell converter with a reported launch problem. Use the ZIP linked at the top for these current launchers. The old release asset has not been replaced.

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

[Report a problem](https://github.com/Fsas12/flac-to-wav-dj/issues/new) with your operating system version, FFmpeg version, the launcher you used (Windows BAT, macOS .command, or v1.0.0), and the error text without personal information. Do not upload your music library; use synthetic test audio for examples.

Small pull requests are welcome.

## License and credits

The scripts and documentation are released under the [MIT License](LICENSE). FFmpeg is a separate project with its own license; its binary is not distributed here. This utility is not affiliated with a DJ equipment manufacturer.
