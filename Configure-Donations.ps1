#Requires -Version 5.1
[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$Url)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$uri = $null
if (-not [Uri]::TryCreate($Url, [UriKind]::Absolute, [ref]$uri) -or $uri.Scheme -ne 'https' -or -not $uri.Host -or $uri.UserInfo) {
    throw 'Provide a public HTTPS donation-page URL, without embedded credentials.'
}
$safeUrl = $uri.AbsoluteUri.Replace('(', '%28').Replace(')', '%29')
$marker = '(?s)<!-- donation:start -->.*?<!-- donation:end -->'
$utf8 = [Text.UTF8Encoding]::new($false)
$updates = @(
    @{Name='README.md'; Text=('If this saves you time, you can [support the project](' + $safeUrl + '). Thank you!')},
    @{Name='README.ru.md'; Text=('[Поддержать автора](' + $safeUrl + '). Спасибо, что помогаешь развивать проект!')}
)
# Validate all target sections before writing anything.
foreach ($update in $updates) {
    $update.Path = Join-Path $PSScriptRoot $update.Name
    $update.Content = [IO.File]::ReadAllText($update.Path)
    if ([regex]::Matches($update.Content, $marker).Count -ne 1) { throw ('Donation section missing or duplicated: ' + $update.Name) }
}
foreach ($update in $updates) {
    $replacement = '<!-- donation:start -->' + [Environment]::NewLine + $update.Text + [Environment]::NewLine + '<!-- donation:end -->'
    $content = [regex]::Replace($update.Content, $marker, [Text.RegularExpressions.MatchEvaluator]{param($match) $replacement})
    [IO.File]::WriteAllText($update.Path, $content, $utf8)
}
$funding = Join-Path $PSScriptRoot '.github\FUNDING.yml'
# YAML single quotes escape themselves by doubling.
$yaml = "custom: ['" + $safeUrl.Replace("'", "''") + "']" + [Environment]::NewLine
[IO.File]::WriteAllText($funding, $yaml, $utf8)
Write-Host 'Donation link updated in both READMEs and .github/FUNDING.yml.'
Write-Host 'Commit and push these three files to activate the link on GitHub.'
