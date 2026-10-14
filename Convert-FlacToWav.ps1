#Requires -Version 5.1
[CmdletBinding()]
param(
    [string]$InputDirectory = $PSScriptRoot,
    [string]$OutputDirectory,
    [ValidateSet(16,24)][int]$BitDepth = 16,
    [ValidateSet(0,44100,48000)][int]$SampleRate = 0,
    [switch]$Recurse,
    [string]$FFmpegPath
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
try {
    $source = Get-Item -LiteralPath $InputDirectory
    if (-not $source.PSIsContainer) { throw 'InputDirectory must be a folder.' }
    $sourceRoot = $source.FullName.TrimEnd([IO.Path]::DirectorySeparatorChar)
    if (-not $OutputDirectory) { $OutputDirectory = Join-Path $sourceRoot 'wav' }
    $outputRoot = [IO.Path]::GetFullPath($OutputDirectory)
    if ($FFmpegPath) {
        $ffmpeg = (Get-Item -LiteralPath $FFmpegPath).FullName
    } elseif (Test-Path -LiteralPath (Join-Path $PSScriptRoot 'ffmpeg.exe') -PathType Leaf) {
        $ffmpeg = Join-Path $PSScriptRoot 'ffmpeg.exe'
    } else {
        $command = Get-Command ffmpeg.exe -CommandType Application -ErrorAction SilentlyContinue
        if (-not $command) { throw 'FFmpeg not found. Put ffmpeg.exe beside the scripts, or add it to PATH. See README.' }
        $ffmpeg = $command.Source
    }
    $scan = @{LiteralPath=$sourceRoot; File=$true; ErrorAction='Stop'}
    if ($Recurse) { $scan.Recurse = $true }
    $files = @(Get-ChildItem @scan | Where-Object { $_.Extension -ieq '.flac' } | Sort-Object FullName)
    if ($files.Count -eq 0) { Write-Host 'No FLAC files found. Nothing to convert.'; exit 0 }
    [IO.Directory]::CreateDirectory($outputRoot) | Out-Null
    $converted = 0; $skipped = 0; $failed = 0; $index = 0
    $results = [Collections.Generic.List[object]]::new()
    Write-Host ('FLAC -> WAV | {0}-bit PCM | {1} files' -f $BitDepth, $files.Count)
    foreach ($file in $files) {
        $index++
        $relative = $file.FullName.Substring($sourceRoot.Length + 1)
        $target = Join-Path $outputRoot ([IO.Path]::ChangeExtension($relative, '.wav'))
        $temp = $null
        if (Test-Path -LiteralPath $target) {
            $skipped++
            Write-Host ('[{0}/{1}] SKIP (already exists): {2}' -f $index, $files.Count, $relative)
            $results.Add([pscustomobject]@{Input=$file.FullName; Output=$target; Status='skipped'; Error=''})
            continue
        }
        try {
            $targetFolder = [IO.Path]::GetDirectoryName($target)
            [IO.Directory]::CreateDirectory($targetFolder) | Out-Null
            $temp = Join-Path $targetFolder ('.flac-to-wav-' + [Guid]::NewGuid().ToString('N') + '.wav')
            $ffmpegArgs = @('-hide_banner','-nostdin','-n','-loglevel','error','-i',$file.FullName,
                '-map','0:a:0','-vn','-map_metadata','0','-c:a',('pcm_s{0}le' -f $BitDepth))
            if ($SampleRate -gt 0) { $ffmpegArgs += @('-ar', $SampleRate.ToString()) }
            $ffmpegArgs += @('-f','wav',$temp)
            Write-Host ('[{0}/{1}] CONVERT: {2}' -f $index, $files.Count, $relative)
            # Launch directly without cmd.exe. Every argument is quoted separately.
            # Windows filenames cannot contain a double quote; double terminal slashes.
            $startInfo = [Diagnostics.ProcessStartInfo]::new()
            $startInfo.FileName = $ffmpeg
            $startInfo.Arguments = ($ffmpegArgs | ForEach-Object { '"' + ($_ -replace '(\\+)$', '$1$1') + '"' }) -join ' '
            $startInfo.UseShellExecute = $false
            $startInfo.CreateNoWindow = $true
            $startInfo.RedirectStandardError = $true
            $process = [Diagnostics.Process]::new()
            $process.StartInfo = $startInfo
            try {
                if (-not $process.Start()) { throw 'Could not start FFmpeg.' }
                $messages = $process.StandardError.ReadToEnd()
                $process.WaitForExit()
                $nativeExit = $process.ExitCode
            } finally { $process.Dispose() }
            if ($nativeExit -ne 0) { throw ('FFmpeg failed (exit {0}): {1}' -f $nativeExit, ($messages -join ' ')) }
            if (-not (Test-Path -LiteralPath $temp -PathType Leaf) -or (Get-Item -LiteralPath $temp).Length -eq 0) {
                throw 'FFmpeg did not produce a valid output file.'
            }
            # File.Move refuses to overwrite a file created by another process meanwhile.
            [IO.File]::Move($temp,$target)
            $temp = $null
            $converted++
            $results.Add([pscustomobject]@{Input=$file.FullName; Output=$target; Status='converted'; Error=''})
        } catch {
            $failed++
            Write-Host ('ERROR: {0} | {1}' -f $relative, $_.Exception.Message) -ForegroundColor Red
            $results.Add([pscustomobject]@{Input=$file.FullName; Output=$target; Status='failed'; Error=$_.Exception.Message})
        } finally {
            if ($temp -and (Test-Path -LiteralPath $temp)) { Remove-Item -LiteralPath $temp -Force }
        }
    }
    $log = Join-Path $outputRoot ('conversion-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '-' + [Guid]::NewGuid().ToString('N').Substring(0,8) + '.csv')
    $results | Export-Csv -LiteralPath $log -NoTypeInformation -Encoding UTF8
    Write-Host ('Done. Converted: {0} | Skipped: {1} | Failed: {2}' -f $converted, $skipped, $failed)
    Write-Host ('Output: ' + $outputRoot)
    Write-Host ('Log: ' + $log)
    if ($failed -gt 0) { exit 1 }
    exit 0
} catch {
    Write-Host ('ERROR: ' + $_.Exception.Message) -ForegroundColor Red
    exit 2
}
