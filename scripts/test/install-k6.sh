#!/usr/bin/env bash
#
# Cài đặt Grafana k6 v2.3.0 trên Ubuntu/Debian (amd64 hoặc arm64).
# Cách dùng: sudo bash scripts/test/install-k6.sh
#
set -Eeuo pipefail

readonly K6_VERSION="2.3.0"
readonly KEYRING_DIR="/usr/share/keyrings"
readonly KEYRING_FILE="${KEYRING_DIR}/k6-archive-keyring.gpg"
readonly REPO_FILE="/etc/apt/sources.list.d/k6.list"

log() {
  printf '[INFO] %s\n' "$*"
}

fail() {
  printf '[ERROR] %s\n' "$*" >&2
  exit 1
}

on_error() {
  local exit_code=$?
  printf '[ERROR] Cài đặt thất bại gần dòng %s (mã thoát: %s).\n' \
    "${BASH_LINENO[0]:-unknown}" "$exit_code" >&2
  exit "$exit_code"
}
trap on_error ERR

[[ "${EUID}" -eq 0 ]] || fail "Hãy chạy script này bằng sudo hoặc với quyền root."
[[ -r /etc/os-release ]] || fail "Không xác định được hệ điều hành: thiếu file /etc/os-release."

# shellcheck disable=SC1091
source /etc/os-release
case "${ID:-}" in
  ubuntu|debian) ;;
  *) fail "Hệ điều hành không được hỗ trợ: ${PRETTY_NAME:-unknown}. Script này chỉ hỗ trợ Ubuntu và Debian." ;;
esac

architecture="$(dpkg --print-architecture)"
case "$architecture" in
  amd64|arm64) ;;
  *) fail "Kiến trúc không được hỗ trợ: ${architecture}. Chỉ hỗ trợ: amd64, arm64." ;;
esac

if command -v k6 >/dev/null 2>&1; then
  installed_version="$(k6 version 2>/dev/null | awk 'NR==1 {print $2}' | sed 's/^v//' || true)"
  if [[ "$installed_version" == "$K6_VERSION" ]]; then
    log "k6 ${K6_VERSION} đã được cài đặt; không cần làm gì thêm."
    exit 0
  fi
  log "Phiên bản k6 hiện có: ${installed_version:-unknown}. Script sẽ yêu cầu cài đúng phiên bản ${K6_VERSION}."
fi

export DEBIAN_FRONTEND=noninteractive

log "Đang cài các gói phụ thuộc cần thiết..."
apt-get update
apt-get install -y --no-install-recommends ca-certificates curl gnupg

log "Đang thêm khóa ký APT chính thức của k6..."
install -d -m 0755 "$KEYRING_DIR"
curl -fsSL https://dl.k6.io/key.gpg \
  | gpg --dearmor --yes -o "$KEYRING_FILE"
chmod 0644 "$KEYRING_FILE"

log "Đang thêm kho APT chính thức của k6..."
cat > "$REPO_FILE" <<EOF
deb [signed-by=${KEYRING_FILE}] https://dl.k6.io/deb stable main
EOF
chmod 0644 "$REPO_FILE"

log "Đang làm mới metadata APT..."
apt-get update

package_version="$(
  apt-cache madison k6 \
    | awk '{print $3}' \
    | grep -E "^${K6_VERSION}([.+:~-]|$)" \
    | head -n 1 || true
)"
[[ -n "$package_version" ]] || fail "Không tìm thấy k6 ${K6_VERSION} cho kiến trúc ${architecture} trong kho đã cấu hình. Script sẽ không cài phiên bản khác."

log "Đang cài gói k6 đúng phiên bản ${package_version}..."
apt-get install -y --no-install-recommends --allow-downgrades "k6=${package_version}"

installed_version="$(k6 version 2>/dev/null | awk 'NR==1 {print $2}' | sed 's/^v//' || true)"
[[ "$installed_version" == "$K6_VERSION" ]] \
  || fail "Kiểm tra phiên bản thất bại: cần ${K6_VERSION}, nhận được ${installed_version:-unknown}."

log "Cài đặt thành công."
k6 version
