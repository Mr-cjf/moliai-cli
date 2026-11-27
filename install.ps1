<#
.SYNOPSIS
  MoliAi CLI 一键安装脚本（Windows x64；ARM64 通过系统 x64 模拟运行）

.DESCRIPTION
  用法（PowerShell）：
    irm https://github.com/Mr-cjf/moliai-cli/releases/download/v0.10.6/install.ps1 | iex

  先下载再执行：
    .\install.ps1
    .\install.ps1 -Version v0.10.6 -InstallDir D:\tools\moliai
    .\install.ps1 -WhatIf          # 只打印计划，不下载不写入

.PARAMETER Version
  版本号，默认 v0.10.6（含 v 前缀）。也可用环境变量 MOLIAI_VERSION 覆盖。

.PARAMETER InstallDir
  安装目录，默认 $env:USERPROFILE\bin。也可用环境变量 MOLIAI_INSTALL_DIR 覆盖。

.PARAMETER WhatIf
  只输出将要执行的动作，不下载、不安装、不改 Path。

.EXAMPLE
  .\install.ps1 -WhatIf
#>
[CmdletBinding()]
param(
    [string]$Version = $(if ($env:MOLIAI_VERSION) { $env:MOLIAI_VERSION } else { 'v0.10.6' }),
    [string]$InstallDir = $(if ($env:MOLIAI_INSTALL_DIR) { $env:MOLIAI_INSTALL_DIR } else { Join-Path $env:USERPROFILE 'bin' }),
    [switch]$WhatIf
)

$ErrorActionPreference = 'Stop'

$Repo = 'Mr-cjf/moliai-cli'
$AssetName = 'moliai-windows-x64.exe'
$TempDir = $null

function Write-Step([string]$Message) {
    Write-Host "==> $Message" -ForegroundColor Cyan
}

function Write-Ok([string]$Message) {
    Write-Host "[OK] $Message" -ForegroundColor Green
}

function Write-Note([string]$Message) {
    Write-Host "[注意] $Message" -ForegroundColor Yellow
}

function Assert-WindowsX64 {
    if (-not [Environment]::Is64BitOperatingSystem) {
        throw '不支持 32 位 Windows。官方构建仅提供：Windows x64、macOS arm64、macOS x64、Linux x64'
    }
    $arch = $env:PROCESSOR_ARCHITECTURE
    # ARM64 机器上跑 x64 模拟的 PowerShell 时，真实架构在 PROCESSOR_ARCHITEW6432
    $archWow = $env:PROCESSOR_ARCHITEW6432
    if ($arch -eq 'ARM64' -or $archWow -eq 'ARM64') {
        # 无原生 ARM64 构建，但 Win11 ARM 的 x64 模拟可用，故只警告不拦截
        Write-Warning '检测到 Windows ARM64：未提供原生 ARM64 构建，将安装 x64 版本并通过系统 x64 模拟运行'
        Write-Host "平台：Windows / ARM64（x64 模拟） -> $AssetName"
    }
    elseif ($arch -and $arch -ne 'AMD64') {
        throw "不支持的 Windows 架构：$arch。官方构建仅提供：Windows x64、macOS arm64、macOS x64、Linux x64"
    }
    else {
        Write-Host "平台：Windows / x64 -> $AssetName"
    }
}

function Get-RemoteFile([string]$Url, [string]$OutFile) {
    $curl = Get-Command 'curl.exe' -ErrorAction SilentlyContinue
    if ($curl) {
        # 交互式终端用单行进度条，重定向/日志场景静默，避免进度刷屏
        $isInteractive = -not [Console]::IsOutputRedirected
        if ($isInteractive) {
            $curlArgs = @('-fL', '--retry', '2', '--connect-timeout', '15', '--progress-bar', '-o', $OutFile, $Url)
        }
        else {
            $curlArgs = @('-fLsS', '--retry', '2', '--connect-timeout', '15', '-o', $OutFile, $Url)
        }
        & $curl.Source @curlArgs
        if ($LASTEXITCODE -ne 0) {
            throw "下载失败，检查网络或代理：$Url"
        }
        return
    }
    $oldProgress = $ProgressPreference
    $ProgressPreference = 'SilentlyContinue'
    try {
        Invoke-WebRequest -Uri $Url -OutFile $OutFile -UseBasicParsing
    }
    catch {
        throw "下载失败，检查网络或代理：$Url（$($_.Exception.Message)）"
    }
    finally {
        $ProgressPreference = $oldProgress
    }
}

# 输出被重定向（irm ... | iex > install.log）时控制台编码是 OEM/GBK，中文日志会写成 GBK。
# 仅在重定向时切 UTF-8，并在 finally 中恢复，避免污染调用方的 PowerShell 会话。
$script:OriginalOutputEncoding = $null

try {
    if ([Console]::IsOutputRedirected) {
        $script:OriginalOutputEncoding = [Console]::OutputEncoding
        [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    }

    Write-Host ''
    Write-Host "MoliAi CLI 安装器（版本 $Version）" -ForegroundColor White
    Write-Host ''

    Assert-WindowsX64

    $BaseUrl = "https://github.com/$Repo/releases/download/$Version"
    $target = Join-Path $InstallDir 'moliai.exe'

    if ($WhatIf) {
        Write-Host ''
        Write-Host '[-WhatIf] 只打印计划，不下载、不写入：' -ForegroundColor Yellow
        Write-Host "  下载地址：$BaseUrl/$AssetName"
        Write-Host "  校验文件：$BaseUrl/SHA256SUMS.txt"
        Write-Host "  安装目标：$target"
        Write-Host "  用户级 Path 追加：$InstallDir"
        Write-Host ''
        return
    }

    $TempDir = Join-Path ([System.IO.Path]::GetTempPath()) ('moliai-install-' + [Guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $TempDir -Force | Out-Null

    $BinaryPath = Join-Path $TempDir $AssetName
    $SumsPath = Join-Path $TempDir 'SHA256SUMS.txt'

    Write-Step "下载 $AssetName ..."
    Get-RemoteFile "$BaseUrl/$AssetName" $BinaryPath

    Write-Step '下载 SHA256SUMS.txt ...'
    Get-RemoteFile "$BaseUrl/SHA256SUMS.txt" $SumsPath

    Write-Step '校验 SHA256 ...'
    $expected = $null
    foreach ($line in Get-Content -LiteralPath $SumsPath) {
        $parts = $line -split '\s+', 2
        if ($parts.Count -eq 2 -and $parts[1].Trim() -eq $AssetName) {
            $expected = $parts[0].Trim().ToLowerInvariant()
            break
        }
    }
    if (-not $expected) {
        throw "SHA256SUMS.txt 中没有 $AssetName 的校验值。版本 $Version 可能缺少该平台构建"
    }
    $actual = (Get-FileHash -LiteralPath $BinaryPath -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($actual -ne $expected) {
        throw "SHA256 校验失败，已停止安装。期望：$expected 实际：$actual"
    }
    Write-Ok 'SHA256 校验通过'

    if (-not (Test-Path -LiteralPath $InstallDir)) {
        Write-Step "创建安装目录 $InstallDir ..."
        New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
    }

    Write-Step "安装到 $target ..."
    Move-Item -LiteralPath $BinaryPath -Destination $target -Force
    Write-Ok "已安装到 $target"

    # 只改用户级 Path，不动系统级
    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    if (-not $userPath) { $userPath = '' }
    $alreadyInPath = $false
    foreach ($entry in @($userPath -split ';' | Where-Object { $_ -ne '' })) {
        if ($entry.Trim().TrimEnd('\') -ieq $InstallDir.TrimEnd('\')) { $alreadyInPath = $true; break }
    }

    Write-Host ''
    if ($alreadyInPath) {
        Write-Ok "用户级 Path 已包含 $InstallDir，跳过"
    }
    else {
        $newPath = if ($userPath.Trim() -eq '') { $InstallDir } else { $userPath.TrimEnd(';') + ';' + $InstallDir }
        [Environment]::SetEnvironmentVariable('Path', $newPath, 'User')
        Write-Ok "已把 $InstallDir 加入用户级 Path（仅当前用户，未改系统级）"
        Write-Note 'Path 变更只对新开的终端生效，请关闭当前终端后重新打开'
    }

    Write-Step '验证安装 ...'
    $versionRaw = (& cmd.exe /c "`"$target`" --version 2>&1") -join ' '
    $versionExit = $LASTEXITCODE
    if ($versionExit -ne 0) {
        throw "执行 moliai.exe --version 失败（退出码 $versionExit）：$versionRaw"
    }

    Write-Host ''
    Write-Ok "安装完成，版本：$($versionRaw.Trim())"
    Write-Host '   下一步：moliai login key --base-url "<你的 API 网关地址>"'
    Write-Host '   帮助：moliai help'
    Write-Host ''
}
catch {
    Write-Host ''
    Write-Host "[错误] $($_.Exception.Message)" -ForegroundColor Red
    # 用 throw 而非 exit：通过 `irm ... | iex` 执行时 exit 会关掉用户当前 PowerShell 会话
    throw
}
finally {
    # 恢复调用方会话的控制台输出编码（irm | iex 在用户当前会话执行，不能污染）
    if ($null -ne $script:OriginalOutputEncoding) {
        [Console]::OutputEncoding = $script:OriginalOutputEncoding
    }
    if ($TempDir -and (Test-Path -LiteralPath $TempDir)) {
        Remove-Item -LiteralPath $TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}
