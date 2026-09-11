#!/usr/bin/env bash
#===============================================================================
#  xcc install.sh
#  Author : xcc
#  Version: 1.0.0
#  Description: 从 GitHub 部署 xcc 到 /usr/local/bin/xcc，并启动首次配置向导
#===============================================================================

set -uo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

XCC_GITHUB_USER="${XCC_GITHUB_USER:-wang-xinchen007}"
XCC_GITHUB_REPO="${XCC_GITHUB_REPO:-xcc}"
XCC_GITHUB_BRANCH="${XCC_GITHUB_BRANCH:-main}"
XCC_RAW_BASE="https://raw.githubusercontent.com/${XCC_GITHUB_USER}/${XCC_GITHUB_REPO}/${XCC_GITHUB_BRANCH}"
XCC_BIN="/usr/local/bin/xcc"
XCC_DIR="/etc/xcc"
XCC_TMP_DIR="/var/tmp/xcc"

info()  { printf '%b[INFO]%b %s\n' "${GREEN}" "${NC}" "$*"; }
warn()  { printf '%b[WARN]%b %s\n' "${YELLOW}" "${NC}" "$*"; }
err()   { printf '%b[ERROR]%b %s\n' "${RED}" "${NC}" "$*" >&2; }
die()   { err "$*"; exit 1; }

need_root() {
  if [[ "${EUID}" -ne 0 ]]; then
    die "请使用 root 运行安装脚本（sudo bash install.sh）"
  fi
}

detect_os() {
  if [[ -f /etc/os-release ]]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    printf '%s %s\n' "${ID:-unknown}" "${VERSION_ID:-unknown}"
  else
    printf 'unknown unknown\n'
  fi
}

install_curl() {
  if command -v curl >/dev/null 2>&1; then
    return 0
  fi
  info "未检测到 curl，正在安装..."
  if command -v apt-get >/dev/null 2>&1; then
    export DEBIAN_FRONTEND=noninteractive
    DEBIAN_FRONTEND=noninteractive apt-get update -y
    DEBIAN_FRONTEND=noninteractive apt-get install -y curl ca-certificates
  elif command -v dnf >/dev/null 2>&1; then
    dnf install -y curl ca-certificates
  elif command -v yum >/dev/null 2>&1; then
    yum install -y curl ca-certificates
  else
    die "无法安装 curl，请手动安装后重试。"
  fi
}

# 每个下载操作使用 curl -f；失败时删除不完整文件并提示重试。
download_file() {
  local dest="$1"
  local url="$2"
  if ! curl -fL -A "xcc-install/1.0.0" --retry 3 --retry-delay 2 --connect-timeout 15 --max-time 180 -o "${dest}" "${url}"; then
    rm -f "${dest}"
    die "下载失败，请检查网络后重试: ${url}"
  fi
}

main() {
  need_root
  mkdir -p "${XCC_TMP_DIR}" "${XCC_DIR}"
  chmod 700 "${XCC_DIR}" "${XCC_TMP_DIR}"

  local os_id os_ver
  read -r os_id os_ver < <(detect_os)
  info "检测到系统: ${os_id} ${os_ver}"
  info "目标仓库: ${XCC_RAW_BASE}"

  install_curl

  local tmp
  tmp=$(mktemp "${XCC_TMP_DIR}/xcc-XXXXXX")
  info "正在下载 xcc 主脚本..."
  download_file "${tmp}" "${XCC_RAW_BASE}/xcc"

  if ! grep -q '^XCC_VERSION=' "${tmp}"; then
    rm -f "${tmp}"
    die "下载的文件不是有效的 xcc 脚本，请检查仓库地址。"
  fi

  chmod 755 "${tmp}"
  mv "${tmp}" "${XCC_BIN}"
  chmod 755 "${XCC_BIN}"
  info "已安装 ${XCC_BIN}"
  info "配置目录 ${XCC_DIR} 将在首次运行时初始化（已有配置不会被覆盖）"

  printf '%b即将启动 xcc run 首次配置向导...%b\n' "${BLUE}" "${NC}"
  exec "${XCC_BIN}" run
}

main "$@"
