#!/usr/bin/env bash
# Cài Nginx 1.24.0, Node Exporter 1.12.1 và process-exporter 0.8.7 trên VM Server (Ubuntu Server 24.04),
# đồng thời tạo tệp benchmark 65.536 byte và cấu hình Nginx phục vụ tệp đó.
# Cách dùng: sudo ./setup-server.sh
# Các biến tùy chọn: MONITORING_IP (mặc định 192.168.100.20), TEST_IP (mặc định 192.168.100.30)
# Hướng dẫn thủ công tương ứng: docs/server-manual-setup.md
set -euo pipefail

NGINX_VERSION="1.24.0"
NODE_EXPORTER_VERSION="1.12.1"
PROCESS_EXPORTER_VERSION="0.8.7"
MONITORING_IP="${MONITORING_IP:-192.168.100.20}"
TEST_IP="${TEST_IP:-192.168.100.30}"

# Tệp benchmark: byte 0..255 lặp 256 lần, đúng 65.536 byte. Mã băm này được tính trước
# và là chuẩn để kiểm tra; nếu không khớp, dừng ngay.
PAYLOAD_DIR="/var/www/benchmark"
PAYLOAD_PATH="$PAYLOAD_DIR/payload.bin"
PAYLOAD_SIZE=65536
PAYLOAD_SHA256="7daca2095d0438260fa849183dfc67faa459fdf4936e1bc91eec6b281b27e4c2"
MANIFEST_DIR="/etc/benchmark"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NGINX_BENCH_CONF_SRC="$SCRIPT_DIR/../../configs/nginx/benchmark.conf"

WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

log() { printf '\n[%s] %s\n' "$(date +%H:%M:%S)" "$*"; }
die() { printf '\nLỖI: %s\n' "$*" >&2; exit 1; }

check_prerequisites() {
    [[ $EUID -eq 0 ]] || die "Chạy script bằng sudo."
    # shellcheck disable=SC1091
    . /etc/os-release
    [[ "$ID" == "ubuntu" && "$VERSION_ID" == "24.04" ]] \
        || die "Script chỉ kiểm thử trên Ubuntu 24.04, máy hiện tại là: ${PRETTY_NAME:-không rõ}."
    log "Cài các gói phụ trợ"
    apt-get update
    apt-get install -y curl ufw python3
}

# Tải archive từ GitHub release, kiểm tra checksum rồi giải nén vào $WORK_DIR.
# Tham số: repo, phiên bản, tên archive, tên file checksum
download_verified() {
    local repo="$1" version="$2" archive="$3" checksum_file="$4"
    local base="https://github.com/${repo}/releases/download/v${version}"

    curl -fsSL -o "$WORK_DIR/$archive" "$base/$archive"
    curl -fsSL -o "$WORK_DIR/$checksum_file" "$base/$checksum_file"

    (cd "$WORK_DIR" && awk -v f="$archive" '$2==f' "$checksum_file" | sha256sum -c -) \
        || die "Checksum của $archive không khớp."

    tar -xzf "$WORK_DIR/$archive" -C "$WORK_DIR"
}

install_nginx() {
    log "Cài Nginx ${NGINX_VERSION}"
    apt-get install -y "nginx=${NGINX_VERSION}*"
    systemctl enable nginx
    systemctl restart nginx
}

install_node_exporter() {
    log "Cài Node Exporter ${NODE_EXPORTER_VERSION}"
    local dir="node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64"

    download_verified prometheus/node_exporter "$NODE_EXPORTER_VERSION" "$dir.tar.gz" sha256sums.txt
    install -m 0755 "$WORK_DIR/$dir/node_exporter" /usr/local/bin/node_exporter

    id node_exporter &>/dev/null \
        || useradd --system --no-create-home --shell /usr/sbin/nologin node_exporter

    cat > /etc/systemd/system/node_exporter.service <<EOF
[Unit]
Description=Prometheus Node Exporter ${NODE_EXPORTER_VERSION}
Wants=network-online.target
After=network-online.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter --web.listen-address=:9100
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable node_exporter
    systemctl restart node_exporter
}

install_process_exporter() {
    log "Cài process-exporter ${PROCESS_EXPORTER_VERSION}"
    local dir="process-exporter-${PROCESS_EXPORTER_VERSION}.linux-amd64"

    download_verified ncabatoff/process-exporter "$PROCESS_EXPORTER_VERSION" "$dir.tar.gz" checksums.txt
    install -m 0755 "$WORK_DIR/$dir/process-exporter" /usr/local/bin/process-exporter

    mkdir -p /etc/process-exporter
    cat > /etc/process-exporter/config.yml <<'EOF'
process_names:
  - name: "nginx"
    comm:
      - nginx
  - name: "{{.Comm}}"
    cmdline:
      - '.+'
EOF

    # Chạy bằng root để đọc được /proc của tiến trình thuộc user khác.
    cat > /etc/systemd/system/process-exporter.service <<EOF
[Unit]
Description=Prometheus process-exporter ${PROCESS_EXPORTER_VERSION}
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
ExecStart=/usr/local/bin/process-exporter -config.path /etc/process-exporter/config.yml -web.listen-address :9256
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable process-exporter
    systemctl restart process-exporter
}

prepare_payload() {
    log "Tạo tệp benchmark ${PAYLOAD_SIZE} byte tại ${PAYLOAD_PATH}"
    install -d -m 0755 "$PAYLOAD_DIR"
    python3 -c "import sys; open(sys.argv[1], 'wb').write(bytes(range(256)) * 256)" "$PAYLOAD_PATH"
    chmod 0644 "$PAYLOAD_PATH"

    [[ "$(stat -c %s "$PAYLOAD_PATH")" == "$PAYLOAD_SIZE" ]] \
        || die "Kích thước payload không đúng: $(stat -c %s "$PAYLOAD_PATH") byte."
    [[ "$(sha256sum "$PAYLOAD_PATH" | cut -d' ' -f1)" == "$PAYLOAD_SHA256" ]] \
        || die "SHA-256 của payload không khớp giá trị chuẩn."

    install -d -m 0755 "$MANIFEST_DIR"
    cat > "$MANIFEST_DIR/manifest.txt" <<EOF
# Manifest tệp phục vụ
Đường dẫn: /benchmark/payload.bin
Kích thước (byte): ${PAYLOAD_SIZE}
Nội dung: byte 0..255 lặp 256 lần
SHA-256: ${PAYLOAD_SHA256}
Tạo lúc: $(date -Is)

# Cấu hình VM Server
OS: $(lsb_release -ds)
Kernel: $(uname -r)
vCPU: $(nproc)
RAM: $(free -m | awk '/Mem:/{print $2" MiB"}')
Nginx: $(nginx -v 2>&1)
IP: $(hostname -I | awk '{print $1}')
EOF
}

configure_benchmark_site() {
    log "Cấu hình site benchmark cho Nginx"
    [[ -f "$NGINX_BENCH_CONF_SRC" ]] || die "Không thấy file cấu hình: $NGINX_BENCH_CONF_SRC"
    install -m 0644 "$NGINX_BENCH_CONF_SRC" /etc/nginx/sites-available/benchmark
    rm -f /etc/nginx/sites-enabled/default
    ln -sfn /etc/nginx/sites-available/benchmark /etc/nginx/sites-enabled/benchmark
    nginx -t
    systemctl reload nginx
}

configure_firewall() {
    log "Cấu hình UFW: 80 cho ${TEST_IP}; 9100 và 9256 cho ${MONITORING_IP}"
    ufw allow OpenSSH
    ufw allow from "$TEST_IP" to any port 80 proto tcp
    ufw allow from "$MONITORING_IP" to any port 9100 proto tcp
    ufw allow from "$MONITORING_IP" to any port 9256 proto tcp
    ufw --force enable
}

verify() {
    log "Kiểm tra dịch vụ và endpoint"
    local svc metrics
    for svc in nginx node_exporter process-exporter; do
        systemctl is-active --quiet "$svc" || die "$svc không chạy. Xem: journalctl -u $svc -n 50"
    done

    curl -fsS -o /dev/null http://127.0.0.1/ || die "Nginx không trả lời HTTP."

    local code
    code="$(curl -sS -o "$WORK_DIR/check.bin" -w '%{http_code}' \
        -H 'Accept-Encoding: identity' http://127.0.0.1/benchmark/payload.bin)" \
        || die "Không tải được /benchmark/payload.bin."
    [[ "$code" == "200" ]] || die "/benchmark/payload.bin trả về HTTP $code, cần 200."
    [[ "$(stat -c %s "$WORK_DIR/check.bin")" == "$PAYLOAD_SIZE" ]] \
        || die "Phản hồi không đủ ${PAYLOAD_SIZE} byte."
    [[ "$(sha256sum "$WORK_DIR/check.bin" | cut -d' ' -f1)" == "$PAYLOAD_SHA256" ]] \
        || die "SHA-256 của phản hồi không khớp giá trị chuẩn."

    metrics="$(curl -fsS http://127.0.0.1:9100/metrics)" || die "Không đọc được metrics Node Exporter."
    grep -q '^node_cpu_seconds_total' <<<"$metrics" || die "Node Exporter không có metric node_cpu_seconds_total."

    metrics="$(curl -fsS http://127.0.0.1:9256/metrics)" || die "Không đọc được metrics process-exporter."
    grep -q '^namedprocess_namegroup_' <<<"$metrics" || die "process-exporter không có metric namedprocess_namegroup_*."

    log "Hoàn tất."
    echo "Nginx:           $(nginx -v 2>&1)"
    echo "Node Exporter:   ${NODE_EXPORTER_VERSION}"
    echo "process-exporter: ${PROCESS_EXPORTER_VERSION}"
    echo "Cổng: 80 (Nginx), 9100 (Node Exporter), 9256 (process-exporter)"
    echo "Payload: ${PAYLOAD_PATH} (${PAYLOAD_SIZE} byte, SHA-256 ${PAYLOAD_SHA256})"
    echo "Manifest: ${MANIFEST_DIR}/manifest.txt"
}

main() {
    check_prerequisites
    install_nginx
    install_node_exporter
    install_process_exporter
    prepare_payload
    configure_benchmark_site
    configure_firewall
    verify
}

main "$@"
