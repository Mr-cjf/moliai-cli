#!/usr/bin/env sh
#
# MoliAi CLI 一键安装脚本（macOS / Linux）
#
# 用法：
#   curl -fsSL https://github.com/Mr-cjf/moliai-cli/releases/download/v0.5.0/install.sh | sh
#
# 可用环境变量覆盖：
#   MOLIAI_VERSION      版本号，默认 v0.5.0（形如 v0.5.0，含 v 前缀）
#   MOLIAI_INSTALL_DIR  安装目录，默认 $HOME/.local/bin（不可写时用 $HOME/bin）
#
set -eu

REPO="Mr-cjf/moliai-cli"
VERSION="${MOLIAI_VERSION:-v0.5.0}"
BINARY=""
TMP_DIR=""

cleanup() {
  if [ -n "$TMP_DIR" ] && [ -d "$TMP_DIR" ]; then
    rm -rf "$TMP_DIR"
  fi
}

die() {
  printf '\n[错误] %s\n' "$1" >&2
  if [ -n "${2:-}" ]; then
    printf '       %s\n' "$2" >&2
  fi
  exit 1
}

info() {
  printf '==> %s\n' "$1"
}

ok() {
  printf '[OK] %s\n' "$1"
}

trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

# ---------------------------------------------------------------- 平台判断

detect_platform() {
  os_name=$(uname -s 2>/dev/null || echo unknown)
  cpu_arch=$(uname -m 2>/dev/null || echo unknown)

  case "$os_name" in
    Darwin)
      case "$cpu_arch" in
        arm64|aarch64) BINARY="moliai-darwin-arm64" ;;
        x86_64|amd64) BINARY="moliai-darwin-x64" ;;
        *) die "不支持的 macOS 架构：$cpu_arch" "支持：arm64（Apple Silicon）、x86_64（Intel）" ;;
      esac
      ;;
    Linux)
      case "$cpu_arch" in
        x86_64|amd64) BINARY="moliai-linux-x64" ;;
        aarch64|arm64) die "暂不支持 Linux arm64" "官方构建仅提供：macOS arm64、macOS x64、Linux x64、Windows x64" ;;
        *) die "不支持的 Linux 架构：$cpu_arch" "官方构建仅提供：macOS arm64、macOS x64、Linux x64、Windows x64" ;;
      esac
      ;;
    *)
      die "不支持的操作系统：$os_name" "官方构建仅提供：macOS arm64、macOS x64、Linux x64、Windows x64"
      ;;
  esac

  info "检测到平台：$os_name / $cpu_arch -> $BINARY"
}

# ---------------------------------------------------------------- 下载能力

http_get() {
  url="$1"
  out="$2"
  attempt=1
  # 交互终端显示进度条，被管道捕获时静默，避免刷屏
  if [ -t 2 ]; then
    curl_progress="--progress-bar"
  else
    curl_progress="-sS"
  fi

  while [ "$attempt" -le 3 ]; do
    if command -v curl >/dev/null 2>&1; then
      if curl -fL --connect-timeout 15 $curl_progress -o "$out" "$url"; then
        return 0
      fi
    elif command -v wget >/dev/null 2>&1; then
      if wget -q -O "$out" "$url"; then
        return 0
      fi
    else
      die "未找到 curl 或 wget，无法下载" "请先安装 curl 后重试"
    fi

    if [ "$attempt" -lt 3 ]; then
      info "下载失败，第 $attempt 次重试 ..."
      sleep 2
    fi
    attempt=$((attempt + 1))
  done

  die "下载失败，检查网络或代理" "$url"
}

sha256_of() {
  file="$1"
  $HASH_CMD "$file" | awk '{print $1}'
}

# ---------------------------------------------------------------- 安装目录

prepare_install_dir() {
  if [ -n "${MOLIAI_INSTALL_DIR:-}" ]; then
    INSTALL_DIR="$MOLIAI_INSTALL_DIR"
    mkdir -p "$INSTALL_DIR" || die "无法创建安装目录：$INSTALL_DIR"
    [ -w "$INSTALL_DIR" ] || die "安装目录不可写：$INSTALL_DIR" "可用 MOLIAI_INSTALL_DIR 指定其它目录"
  else
    INSTALL_DIR="$HOME/.local/bin"
    if ! mkdir -p "$INSTALL_DIR" 2>/dev/null || [ ! -w "$INSTALL_DIR" ]; then
      INSTALL_DIR="$HOME/bin"
      mkdir -p "$INSTALL_DIR" || die "无法创建安装目录：$INSTALL_DIR"
      [ -w "$INSTALL_DIR" ] || die "安装目录不可写：$INSTALL_DIR" "可用 MOLIAI_INSTALL_DIR 指定其它目录"
    fi
  fi

  info "安装目录：$INSTALL_DIR"
}

# ---------------------------------------------------------------- 主流程

info "MoliAi CLI 安装器（版本 $VERSION）"
detect_platform

if command -v sha256sum >/dev/null 2>&1; then
  HASH_CMD="sha256sum"
elif command -v shasum >/dev/null 2>&1; then
  HASH_CMD="shasum -a 256"
else
  die "未找到 sha256sum / shasum，无法校验文件" "请先安装 coreutils 后重试"
fi

prepare_install_dir

TMP_DIR=$(mktemp -d) || die "无法创建临时目录"
BASE_URL="https://github.com/$REPO/releases/download/$VERSION"

info "下载 $BINARY ..."
http_get "$BASE_URL/$BINARY" "$TMP_DIR/$BINARY"

info "下载 SHA256SUMS.txt ..."
http_get "$BASE_URL/SHA256SUMS.txt" "$TMP_DIR/SHA256SUMS.txt"

info "校验 SHA256 ..."
expected=$(awk -v f="$BINARY" '$2 == f { print $1 }' "$TMP_DIR/SHA256SUMS.txt")
if [ -z "$expected" ]; then
  die "SHA256SUMS.txt 中没有 $BINARY 的校验值" "版本 $VERSION 可能缺少该平台构建"
fi
actual=$(sha256_of "$TMP_DIR/$BINARY")
if [ "$expected" != "$actual" ]; then
  printf '\n[错误] SHA256 校验失败，已停止安装\n' >&2
  printf '       期望：%s\n' "$expected" >&2
  printf '       实际：%s\n' "$actual" >&2
  exit 1
fi
ok "SHA256 校验通过"

chmod +x "$TMP_DIR/$BINARY"

if [ "$(uname -s)" = "Darwin" ]; then
  if command -v xattr >/dev/null 2>&1; then
    xattr -dr com.apple.quarantine "$TMP_DIR/$BINARY" >/dev/null 2>&1 || true
    ok "已移除 macOS 隔离属性"
  else
    info "未找到 xattr，跳过隔离属性处理"
    info "若首次运行提示「无法验证开发者」，在「系统设置 -> 隐私与安全性」中点「仍要打开」"
  fi
fi

mv -f "$TMP_DIR/$BINARY" "$INSTALL_DIR/moliai" || die "安装失败：无法写入 $INSTALL_DIR/moliai"
ok "已安装到 $INSTALL_DIR/moliai"

# ---------------------------------------------------------------- PATH 提示

case ":$PATH:" in
  *":$INSTALL_DIR:"*)
    in_path=yes
    ;;
  *)
    in_path=no
    ;;
esac

printf '\n'
if [ "$in_path" = "yes" ]; then
  ok "$INSTALL_DIR 已在 PATH 中"
elif command -v moliai >/dev/null 2>&1; then
  # 当前 shell 已能解析到 moliai（例如配置文件已被 source 过），不再提示
  :
else
  # 检查常见 shell 配置文件是否已有等价设置，避免重复追加导致同一目录出现两次
  rc_found=""
  for rc in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile" "$HOME/.bash_profile" "$HOME/.zprofile"; do
    [ -f "$rc" ] || continue
    if grep -qF -- "$INSTALL_DIR" "$rc" 2>/dev/null \
      || grep -qE '(\$HOME|\$\{HOME\}|~)/\.local/bin|\.local/bin[^ ]*PATH|PATH[^ ]*\.local/bin' "$rc" 2>/dev/null; then
      printf '  %s 中已存在 PATH 设置\n' "$rc"
      [ -n "$rc_found" ] || rc_found="$rc"
    fi
  done

  if [ -n "$rc_found" ]; then
    printf '[注意] %s 尚未在当前 shell 的 PATH 中\n' "$INSTALL_DIR"
    printf '       配置文件已包含该路径，重开终端或执行 source %s 即可生效\n\n' "$rc_found"
  else
    printf '[注意] %s 不在 PATH 中\n' "$INSTALL_DIR"
    printf '       未在 shell 配置文件中找到对应设置，请追加下面这行后重开终端：\n\n'
    printf '       export PATH="%s:$PATH"\n\n' "$INSTALL_DIR"
  fi
fi

# ---------------------------------------------------------------- 版本验证

printf '==> 验证安装 ...\n'
verify_output=$("$INSTALL_DIR/moliai" --version 2>&1) || die "执行 moliai --version 失败" "$verify_output"

printf '\n'
ok "安装完成，版本：$verify_output"
printf '   下一步：moliai login key --base-url "<你的 API 网关地址>"\n'
printf '   帮助：moliai help\n\n'
