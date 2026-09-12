#!/usr/bin/env bash
#===============================================================================
#  xcc install.sh
#  Author : xcc
#  Version: 2.3.0
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
# 优先走 jsDelivr 等镜像，避免 raw.githubusercontent.com DNS 污染（curl: 6）。
github_file_urls() {
  local file="$1"
  local slug="${XCC_GITHUB_USER}/${XCC_GITHUB_REPO}"
  local branch="${XCC_GITHUB_BRANCH}"
  printf '%s\n' \
    "https://cdn.jsdelivr.net/gh/${slug}@${branch}/${file}" \
    "https://fastly.jsdelivr.net/gh/${slug}@${branch}/${file}" \
    "https://github.com/${slug}/raw/${branch}/${file}" \
    "https://raw.gitmirror.com/${slug}/${branch}/${file}" \
    "https://raw.githubusercontent.com/${slug}/${branch}/${file}" \
    "https://ghproxy.net/https://raw.githubusercontent.com/${slug}/${branch}/${file}"
}

download_file() {
  local dest="$1"
  local file="$2"
  local url
  while IFS= read -r url; do
    [[ -n "${url}" ]] || continue
    info "尝试下载: ${url}"
    if curl -fL -A "xcc-install/2.3.0" --connect-timeout 8 --max-time 90 -o "${dest}" "${url}"; then
      return 0
    fi
    rm -f "${dest}"
  done < <(github_file_urls "${file}")
  die "所有镜像均下载失败。若在国内，请改用: bash <(curl -fsSL https://cdn.jsdelivr.net/gh/${XCC_GITHUB_USER}/${XCC_GITHUB_REPO}@${XCC_GITHUB_BRANCH}/install.sh)"
}

main() {
  need_root
  mkdir -p "${XCC_TMP_DIR}" "${XCC_DIR}"
  chmod 700 "${XCC_DIR}" "${XCC_TMP_DIR}"

  local os_id os_ver
  read -r os_id os_ver < <(detect_os)
  info "检测到系统: ${os_id} ${os_ver}"
  info "目标仓库: ${XCC_GITHUB_USER}/${XCC_GITHUB_REPO}@${XCC_GITHUB_BRANCH}"

  install_curl

  local tmp
  tmp=$(mktemp "${XCC_TMP_DIR}/xcc-XXXXXX")
  info "正在下载 xcc 主脚本..."
  download_file "${tmp}" "xcc"

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
