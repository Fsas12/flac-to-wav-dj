# Recursive FLAC / AIFF conversion. Uses Windows PowerShell and .NET only.
[CmdletBinding()]
param(
    [string]$InputDirectory = $PSScriptRoot,
    [Parameter(Mandatory = $true)][string]$FFmpegPath
)
Set-StrictMode -Version 2
$ErrorActionPreference = 'Stop'
$temporary = $null
try {
    $root = New-Object IO.DirectoryInfo ([IO.Path]::GetFullPath($InputDirectory))
    if (-not $root.Exists) { throw 'The selected input folder does not exist.' }
    if (-not [IO.File]::Exists($FFmpegPath)) { throw 'The FFmpeg executable does not exist.' }
    $prefix = $root.FullName.TrimEnd([char[]]@('\', '/')) + [IO.Path]::DirectorySeparatorChar
    $outputRoot = $prefix + 'wav'
    $folders = New-Object 'System.Collections.Generic.Stack[System.IO.DirectoryInfo]'
    $files = New-Object 'System.Collections.Generic.List[System.IO.FileInfo]'
    $folders.Push($root)
    while ($folders.Count -gt 0) {
        $folder = $folders.Pop()
        foreach ($item in $folder.GetFileSystemInfos()) {
            # Do not follow junctions or symlinks, including links back to a parent.
            if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) { continue }
            if ($item.Attributes -band [IO.FileAttributes]::Directory) {
                if (-not $item.FullName.Equals($outputRoot, [StringComparison]::OrdinalIgnoreCase)) {
                    $folders.Push($item)
                }
            } elseif ($item.Extension.ToLowerInvariant() -in @('.flac', '.aif', '.aiff')) {
                $files.Add($item)
            }
        }
    }
    if ($files.Count -eq 0) {
        Write-Host ('No FLAC or AIFF files found in this folder or its subfolders: ' + $root.FullName)
        exit 0
    }
    [IO.Directory]::CreateDirectory($outputRoot) | Out-Null
    $converted = 0; $skipped = 0; $failed = 0; $index = 0
    Write-Host ('FLAC / AIFF -> WAV | 16-bit PCM | {0} files' -f $files.Count)
    foreach ($file in $files) {
        $index++
        $relative = $file.FullName.Substring($prefix.Length)
        $target = Join-Path $outputRoot ([IO.Path]::ChangeExtension($relative, '.wav'))
        # GetFileSystemEntries also detects existing directories or broken links.
        $targetFolder = [IO.Path]::GetDirectoryName($target)
        if ([IO.Directory]::Exists($targetFolder) -and
            [IO.Directory]::GetFileSystemEntries($targetFolder, [IO.Path]::GetFileName($target)).Length -gt 0) {
            Write-Host ('[{0}/{1}] SKIP (already exists): {2}' -f $index, $files.Count, $relative)
            $skipped++
            continue
        }
        Write-Host ('[{0}/{1}] CONVERT: {2}' -f $index, $files.Count, $relative)
        try {
            [IO.Directory]::CreateDirectory($targetFolder) | Out-Null
            $temporary = Join-Path $targetFolder ('.flac-to-wav-' + [Guid]::NewGuid().ToString('N') + '.wav')
            $arguments = @('-hide_banner', '-nostdin', '-n', '-loglevel', 'error', '-i', $file.FullName,
                '-map', '0:a:0', '-vn', '-map_metadata', '0', '-c:a', 'pcm_s16le', '-f', 'wav', $temporary)
            # Windows filenames cannot contain double quotes. No command shell is used.
            $start = New-Object Diagnostics.ProcessStartInfo
            $start.FileName = $FFmpegPath
            $start.Arguments = ($arguments | ForEach-Object { '"' + $_ + '"' }) -join ' '
            $start.UseShellExecute = $false
            $start.CreateNoWindow = $true
            $start.RedirectStandardError = $true
            $process = New-Object Diagnostics.Process
            $process.StartInfo = $start
            try {
                if (-not $process.Start()) { throw 'FFmpeg could not start.' }
                $errors = $process.StandardError.ReadToEnd()
                $process.WaitForExit()
                if ($process.ExitCode -ne 0) { throw ('FFmpeg failed: ' + $errors) }
            } finally {
                $process.Dispose()
            }
            if (-not [IO.File]::Exists($temporary) -or (New-Object IO.FileInfo $temporary).Length -eq 0) {
                throw 'FFmpeg did not create an output file.'
            }
            try {
                # File.Move refuses to overwrite an output created by another run.
                [IO.File]::Move($temporary, $target)
                $temporary = $null
                $converted++
            } catch {
                if ([IO.File]::Exists($target)) { $skipped++ } else { throw }
            }
        } catch {
            $failed++
            Write-Host ('ERROR: {0} | {1}' -f $relative, $_.Exception.Message)
        } finally {
            if ($temporary -and [IO.File]::Exists($temporary)) { [IO.File]::Delete($temporary) }
            $temporary = $null
        }
    }
    Write-Host ('Done. Converted: {0} | Skipped: {1} | Failed: {2}' -f $converted, $skipped, $failed)
    Write-Host ('Output: ' + $outputRoot)
    if ($failed -gt 0) { exit 1 }
    exit 0
} catch {
    Write-Host ('ERROR: ' + $_.Exception.Message)
    exit 2
} finally {
    if ($temporary -and [IO.File]::Exists($temporary)) { [IO.File]::Delete($temporary) }
}
