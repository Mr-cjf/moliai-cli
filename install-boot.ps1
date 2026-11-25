# MoliAi CLI bootstrap installer.
# ASCII-only on purpose: this file is piped into Invoke-Expression,
# and a UTF-8 BOM would break parsing on both PowerShell 5.1 and 7.x.
#
# Usage:
#   irm https://github.com/Mr-cjf/moliai-cli/releases/download/v0.7.1/install-boot.ps1 | iex
#
# This script does not install anything by itself. It downloads the real
# installer (install.ps1, which carries UTF-8 Chinese messages) to a temp
# file, decodes it explicitly as UTF-8, strips the BOM, and runs it.

$ErrorActionPreference = 'Stop'

$installerUrl = 'https://github.com/Mr-cjf/moliai-cli/releases/download/v0.7.1/install.ps1'
$tempFile = Join-Path ([System.IO.Path]::GetTempPath()) ('moliai-install-' + [guid]::NewGuid().ToString('N') + '.ps1')

$script:oldProgress = $ProgressPreference

try {
    # Windows PowerShell 5.1 renders a progress bar for Invoke-WebRequest, which
    # floods the host when this script is piped into Invoke-Expression.
    $ProgressPreference = 'SilentlyContinue'

    Write-Host '==> Downloading installer...'
    Invoke-WebRequest -Uri $installerUrl -OutFile $tempFile -UseBasicParsing

    # The release asset is served as application/octet-stream without a charset,
    # so Windows PowerShell 5.1 would decode it as ANSI. Read it explicitly as UTF-8.
    $code = [System.IO.File]::ReadAllText($tempFile, [System.Text.Encoding]::UTF8)

    # Strip the BOM if present; Invoke-Expression treats it as part of the first token.
    $code = $code.TrimStart([char]0xFEFF)

    if ([string]::IsNullOrWhiteSpace($code)) {
        throw 'Installer downloaded but content is empty.'
    }

    Invoke-Expression $code
}
finally {
    $ProgressPreference = $script:oldProgress
    if (Test-Path -LiteralPath $tempFile) {
        Remove-Item -LiteralPath $tempFile -Force -ErrorAction SilentlyContinue
    }
}
