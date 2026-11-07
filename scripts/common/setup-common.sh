#!/usr/bin/env bash
# Thiết lập nền dùng chung cho cả ba VM (Server, Monitoring, Test) trên Ubuntu Server 24.04.
# Mục tiêu chính: cùng múi giờ và đồng bộ NTP, để access log của Nginx, kết quả k6 và đồ thị
# Prometheus/Grafana đối chiếu được theo cùng một khoảng thời gian.
#
# Cách dùng:  sudo VM_HOSTNAME=server ./setup-common.sh
#             sudo VM_HOSTNAME=monitoring ./setup-common.sh
#             sudo VM_HOSTNAME=test ./setup-common.sh
#
# Biến:
#   VM_HOSTNAME   bắt buộc: server | monitoring | test
#   TIMEZONE      mặc định Asia/Ho_Chi_Minh (phải giống nhau trên cả ba VM)
#   NTP_SERVERS   mặc định "ntp.ubuntu.com" (cách nhau bởi khoảng trắng)
#   SERVER_IP, MONITORING_IP, TEST_IP   dùng để ghi /etc/hosts
#
# Script không cấu hình IP (xem docs/server-manual-setup.md, mục 2), không bật firewall
# (mỗi VM có luật riêng trong script theo vai trò) và không tạo tài khoản hay mật khẩu.
set -euo pipefail

TIMEZONE="${TIMEZONE:-Asia/Ho_Chi_Minh}"
NTP_SERVERS="${NTP_SERVERS:-ntp.ubuntu.com}"
SERVER_IP="${SERVER_IP:-192.168.100.10}"
MONITORING_IP="${MONITORING_IP:-192.168.100.20}"
TEST_IP="${TEST_IP:-192.168.100.30}"
SYNC_TIMEOUT_SECONDS=90

HOSTS_BEGIN="# BEGIN server-monitoring-lab"
HOSTS_END="# END server-monitoring-lab"

log() { printf '\n[%s] %s\n' "$(date +%H:%M:%S)" "$*"; }
die() { printf '\nLỖI: %s\n' "$*" >&2; exit 1; }

check_prerequisites() {
    [[ $EUID -eq 0 ]] || die "Chạy script bằng sudo."
    # shellcheck disable=SC1091
    . /etc/os-release
    [[ "$ID" == "ubuntu" && "$VERSION_ID" == "24.04" ]] \
        || die "Script chỉ kiểm thử trên Ubuntu 24.04, máy hiện tại là: ${PRETTY_NAME:-không rõ}."

    [[ -n "${VM_HOSTNAME:-}" ]] || die "Thiếu VM_HOSTNAME. Ví dụ: sudo VM_HOSTNAME=server ./setup-common.sh"
    case "$VM_HOSTNAME" in
        server | monitoring | test) ;;
        *) die "VM_HOSTNAME phải là server, monitoring hoặc test (nhận được: $VM_HOSTNAME)." ;;
    esac

    [[ -e "/usr/share/zoneinfo/$TIMEZONE" ]] || die "Múi giờ không hợp lệ: $TIMEZONE"
}

install_packages() {
    log "Cài các gói tiện ích dùng chung"
    apt-get update
    apt-get install -y curl wget ca-certificates gnupg openssh-server
    systemctl enable --now ssh
}

configure_hostname() {
    log "Đặt hostname: ${VM_HOSTNAME}"
    hostnamectl set-hostname "$VM_HOSTNAME"

    # Ghi lại khối riêng trong /etc/hosts; chạy lại thì thay khối cũ, không nhân đôi.
    sed -i "/^${HOSTS_BEGIN}\$/,/^${HOSTS_END}\$/d" /etc/hosts
    cat >> /etc/hosts <<EOF
${HOSTS_BEGIN}
${SERVER_IP} server
${MONITORING_IP} monitoring
${TEST_IP} test
${HOSTS_END}
EOF
}

configure_time() {
    log "Đặt múi giờ ${TIMEZONE} và bật đồng bộ NTP (${NTP_SERVERS})"
    timedatectl set-timezone "$TIMEZONE"

    install -d -m 0755 /etc/systemd/timesyncd.conf.d
    cat > /etc/systemd/timesyncd.conf.d/lab.conf <<EOF
[Time]
NTP=${NTP_SERVERS}
EOF

    timedatectl set-ntp true
    systemctl restart systemd-timesyncd
}

wait_for_time_sync() {
    log "Chờ đồng bộ thời gian (tối đa ${SYNC_TIMEOUT_SECONDS}s)"
    local i
    for ((i = 0; i < SYNC_TIMEOUT_SECONDS; i += 3)); do
        if [[ "$(timedatectl show -p NTPSynchronized --value)" == "yes" ]]; then
            return 0
        fi
        sleep 3
    done
    die "Chưa đồng bộ được NTP. Kiểm tra VM có ra Internet không (ping ${NTP_SERVERS%% *}), hoặc đặt NTP_SERVERS khác."
}

verify() {
    log "Kiểm tra"
    [[ "$(hostname)" == "$VM_HOSTNAME" ]] || die "Hostname không đúng: $(hostname)"
    [[ "$(timedatectl show -p Timezone --value)" == "$TIMEZONE" ]] || die "Múi giờ không đúng."
    [[ "$(timedatectl show -p NTPSynchronized --value)" == "yes" ]] || die "NTP chưa đồng bộ."
    systemctl is-active --quiet ssh || die "Dịch vụ ssh không chạy."

    log "Hoàn tất."
    echo "Hostname:  $(hostname)"
    echo "Múi giờ:   $(timedatectl show -p Timezone --value)"
    echo "Giờ hiện tại: $(date -Is)"
    echo "NTP:       đã đồng bộ"
    timedatectl timesync-status || true
    echo
    echo "So sánh đồng hồ giữa các VM bằng: date -Is   (chạy trên từng VM, lệch không quá vài trăm ms)"
}

main() {
    check_prerequisites
    install_packages
    configure_hostname
    configure_time
    wait_for_time_sync
    verify
}

main "$@"
