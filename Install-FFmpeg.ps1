# One-time, per-user installation. No administrator rights or PATH changes.
[CmdletBinding()]
param(
    [switch]$NonInteractive,
    [string]$InstallDirectory = (Join-Path $env:LOCALAPPDATA 'FLAC-to-WAV-DJ\ffmpeg')
)
$ErrorActionPreference = 'Stop'
$version = '9.0.2'
$downloadUrl = 'https://www.gyan.dev/ffmpeg/builds/packages/ffmpeg-9.0.2-essentials_build.zip'
$expectedHash = '60f467265b1e312373dbcd92200c2618a74850f98d3d078e94296bb3fa2047ba'
$target = Join-Path $InstallDirectory 'ffmpeg.exe'
$temporary = $null
$staging = $null
$client = $null
$form = $null

try {
    if (-not $NonInteractive) { Add-Type -AssemblyName System.Windows.Forms }
    if (Test-Path -LiteralPath $target -PathType Leaf) {
        & $target -version | Out-Null
        if ($LASTEXITCODE -eq 0) { exit 0 }
        throw 'The cached FFmpeg does not run. Remove its folder and try again.'
    }
    if (-not [Environment]::Is64BitOperatingSystem) {
        throw 'This automatic download requires 64-bit Windows 10 or 11.'
    }
    if (-not $NonInteractive) {
        $answer = [System.Windows.Forms.MessageBox]::Show(
            'FFmpeg is missing. Download FFmpeg 9.0.2 (about 109 MB) from gyan.dev and install it for this user? No administrator password is needed.',
            'FLAC / AIFF to WAV - First launch',
            [System.Windows.Forms.MessageBoxButtons]::YesNo,
            [System.Windows.Forms.MessageBoxIcon]::Question
        )
        if ($answer -ne [System.Windows.Forms.DialogResult]::Yes) { exit 1 }
    }
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
    $temporary = Join-Path ([IO.Path]::GetTempPath()) ('flac-to-wav-' + [Guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $temporary | Out-Null
    $archive = Join-Path $temporary 'ffmpeg.zip'
    $expanded = Join-Path $temporary 'expanded'
    $client = New-Object Net.WebClient

    if (-not $NonInteractive) {
        $form = New-Object System.Windows.Forms.Form
        $form.Text = 'FLAC / AIFF to WAV - Setup'
        $form.Width = 480
        $form.Height = 180
        $form.StartPosition = 'CenterScreen'
        $form.ControlBox = $false
        $label = New-Object System.Windows.Forms.Label
        $label.Text = 'Downloading FFmpeg. This is needed only once...'
        $label.AutoSize = $true
        $label.Left = 20
        $label.Top = 20
        $form.Controls.Add($label)
        $progress = New-Object System.Windows.Forms.ProgressBar
        $progress.Style = 'Marquee'
        $progress.Left = 20
        $progress.Top = 50
        $progress.Width = 420
        $form.Controls.Add($progress)
        $cancel = New-Object System.Windows.Forms.Button
        $cancel.Text = 'Cancel'
        $cancel.Left = 180
        $cancel.Top = 90
        $cancel.Add_Click({ $client.CancelAsync() })
        $form.Controls.Add($cancel)
        $form.Show()
        $form.Activate()
    }

    $download = $client.DownloadFileTaskAsync([Uri]$downloadUrl, $archive)
    while (-not $download.IsCompleted) {
        if ($form) { [System.Windows.Forms.Application]::DoEvents() }
        Start-Sleep -Milliseconds 100
    }
    $download.GetAwaiter().GetResult()
    if ($form) {
        $cancel.Enabled = $false
        $label.Text = 'Checking the download and extracting FFmpeg...'
        [System.Windows.Forms.Application]::DoEvents()
    }
    # Use .NET directly: PowerShell module auto-loading can differ across hosts.
    $hashStream = [IO.File]::OpenRead($archive)
    $sha256 = [Security.Cryptography.SHA256]::Create()
    try {
        $actualHash = ([BitConverter]::ToString($sha256.ComputeHash($hashStream))).Replace('-', '').ToLowerInvariant()
    } finally {
        $hashStream.Dispose()
        $sha256.Dispose()
    }
    if ($actualHash -ne $expectedHash) {
        throw 'The FFmpeg download failed its checksum check. Nothing was installed. Please try again.'
    }
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [IO.Compression.ZipFile]::ExtractToDirectory($archive, $expanded)
    $executable = Get-ChildItem -LiteralPath $expanded -Filter 'ffmpeg.exe' -File -Recurse | Select-Object -First 1
    if (-not $executable) { throw 'FFmpeg was not found inside the downloaded archive.' }
    & $executable.FullName -version | Out-Null
    if ($LASTEXITCODE -ne 0) { throw 'The downloaded FFmpeg cannot run on this computer.' }
    New-Item -ItemType Directory -Path $InstallDirectory -Force | Out-Null
    $staging = Join-Path $InstallDirectory ('ffmpeg-' + [Guid]::NewGuid().ToString('N') + '.exe')
    Copy-Item -LiteralPath $executable.FullName -Destination $staging
    Move-Item -LiteralPath $staging -Destination $target
    $staging = $null
    $packageRoot = $executable.Directory.Parent.FullName
    foreach ($name in @('LICENSE', 'README.txt')) {
        $notice = Join-Path $packageRoot $name
        if (Test-Path -LiteralPath $notice -PathType Leaf) {
            Copy-Item -LiteralPath $notice -Destination (Join-Path $InstallDirectory $name) -Force
        }
    }
    Set-Content -LiteralPath (Join-Path $InstallDirectory 'SOURCE.txt') -Encoding UTF8 -Value @(
        "FFmpeg $version - Windows essentials build by Gyan Doshi",
        $downloadUrl,
        "SHA256: $expectedHash",
        'Upstream: https://ffmpeg.org/ - licensing and source: https://www.gyan.dev/ffmpeg/builds/'
    )
    exit 0
} catch {
    $message = $_.Exception.Message
    if (-not $NonInteractive) {
        [System.Windows.Forms.MessageBox]::Show($message, 'FFmpeg setup could not finish', 'OK', 'Error') | Out-Null
    }
    Write-Error $message -ErrorAction Continue
    exit 1
} finally {
    if ($form) { $form.Close(); $form.Dispose() }
    if ($client) { $client.Dispose() }
    if ($staging -and (Test-Path -LiteralPath $staging)) { Remove-Item -LiteralPath $staging -Force -ErrorAction SilentlyContinue }
    if ($temporary -and (Test-Path -LiteralPath $temporary)) { Remove-Item -LiteralPath $temporary -Recurse -Force -ErrorAction SilentlyContinue }
}
