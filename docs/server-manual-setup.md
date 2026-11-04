# Cài thủ công VM Server

Tài liệu này hướng dẫn cài VM Server bằng tay: Nginx, Node Exporter và process-exporter. Mỗi lệnh đều ghi rõ phiên bản. Nếu muốn cài nhanh hơn, dùng script tại [`scripts/server/`](../scripts/server/README.md); kết quả hai cách phải giống nhau.

## 0. Thông số đã chốt

| Thành phần | Phiên bản | Nguồn |
|---|---|---|
| Ubuntu Server | 24.04.5 LTS | ISO từ ubuntu.com |
| Nginx | 1.24.0 (gói apt mặc định của Ubuntu 24.04) | apt |
| Node Exporter | 1.12.1 | github.com/prometheus/node_exporter |
| process-exporter | 0.8.7 | github.com/ncabatoff/process-exporter |

| Thông số | Giá trị |
|---|---|
| Hostname | `server` |
| IP | `192.168.100.10/24` |
| Cổng | 80 (Nginx), 9100 (Node Exporter), 9256 (process-exporter) |
| VM Monitoring | `192.168.100.20` (chỉ được scrape cổng 9100 và 9256) |
| VM Test | `192.168.100.30` (chỉ được gọi cổng 80) |

Cấu hình VM: 1 vCPU, 1.5 GB RAM, 10 GB disk.

Chạy các lệnh dưới đây trên VM Server, đăng nhập bằng user có quyền `sudo`.

## 1. Cài Ubuntu Server 24.04.5

1. Trong VMware Workstation, tạo VM mới với ISO Ubuntu Server 24.04.5 LTS.
2. Cấu hình: 1 vCPU, 1.5 GB RAM, 10 GB disk.
3. Network adapter: chọn **NAT** và kết nối vào VMnet chung của cả nhóm.
4. Khi cài, đặt hostname `server` và bật OpenSSH server.

Kiểm tra phiên bản:

```bash
lsb_release -a
# Distributor ID: Ubuntu
# Release:        24.04
```

## 2. Đặt IP tĩnh

Mở **Virtual Network Editor** trên Windows để lấy subnet và gateway NAT thực tế. Không dùng gateway mặc định nếu chưa kiểm tra.

Xem tên card mạng:

```bash
ip -br address
```

Tắt cloud-init ghi đè cấu hình mạng:

```bash
sudo tee /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg > /dev/null <<'EOF'
network: {config: disabled}
EOF
```

Xem file netplan hiện có:

```bash
ls /etc/netplan/
```

Tạo file cấu hình mới, thay `ens33` bằng tên card mạng ở trên và thay `<GATEWAY_NAT>`, `<DNS>` bằng giá trị thực tế:

```bash
sudo tee /etc/netplan/01-lab.yaml > /dev/null <<'EOF'
network:
  version: 2
  ethernets:
    ens33:
      dhcp4: false
      addresses:
        - 192.168.100.10/24
      routes:
        - to: default
          via: <GATEWAY_NAT>
      nameservers:
        addresses: [<DNS>]
EOF
sudo chmod 600 /etc/netplan/01-lab.yaml
```

Xóa file netplan cũ do installer tạo nếu nó trùng card mạng (ví dụ `00-installer-config.yaml`), rồi áp dụng:

```bash
sudo netplan try
```

`netplan try` tự rollback sau 120 giây nếu bạn không xác nhận, nên an toàn khi sửa qua SSH.

Đặt hostname và kiểm tra:

```bash
sudo hostnamectl set-hostname server
ip -br address
ip route
ping -c 4 192.168.100.20
```

## 3. Cài Nginx 1.24.0

```bash
sudo apt-get update
sudo apt-get install -y nginx=1.24.0*
sudo systemctl enable --now nginx
nginx -v
```

Kết quả `nginx -v` phải là `nginx version: nginx/1.24.0`.

Nếu lệnh `apt-get install` báo không tìm thấy phiên bản, xem các bản đang có bằng `apt-cache madison nginx` và ghi lại bản đã cài vào [`docs/environment.md`](environment.md).

Kiểm tra Nginx:

```bash
curl -I http://127.0.0.1/
# HTTP/1.1 200 OK
```

## 4. Cài Node Exporter 1.12.1

Đặt biến phiên bản để dùng lại trong các lệnh sau:

```bash
export NODE_EXPORTER_VERSION=1.12.1
export NODE_EXPORTER_DIR=node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64
cd /tmp
```

Tải binary và file checksum:

```bash
curl -fLO https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/${NODE_EXPORTER_DIR}.tar.gz
curl -fLO https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/sha256sums.txt
```

Kiểm tra checksum, phải in ra `OK`:

```bash
awk -v f="${NODE_EXPORTER_DIR}.tar.gz" '$2==f' sha256sums.txt | sha256sum -c -
```

Giải nén và cài binary:

```bash
tar -xzf ${NODE_EXPORTER_DIR}.tar.gz
sudo install -m 0755 ${NODE_EXPORTER_DIR}/node_exporter /usr/local/bin/node_exporter
/usr/local/bin/node_exporter --version
```

Tạo user hệ thống không đăng nhập được:

```bash
sudo useradd --system --no-create-home --shell /usr/sbin/nologin node_exporter
```

Tạo service systemd:

```bash
sudo tee /etc/systemd/system/node_exporter.service > /dev/null <<'EOF'
[Unit]
Description=Prometheus Node Exporter 1.12.1
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

sudo systemctl daemon-reload
sudo systemctl enable node_exporter
sudo systemctl restart node_exporter
```

Kiểm tra:

```bash
systemctl is-active node_exporter
curl -s http://127.0.0.1:9100/metrics | grep -m 3 '^node_cpu_seconds_total'
```

## 5. Cài process-exporter 0.8.7

Đặt biến phiên bản:

```bash
export PROCESS_EXPORTER_VERSION=0.8.7
export PROCESS_EXPORTER_DIR=process-exporter-${PROCESS_EXPORTER_VERSION}.linux-amd64
cd /tmp
```

Tải binary và file checksum:

```bash
curl -fLO https://github.com/ncabatoff/process-exporter/releases/download/v${PROCESS_EXPORTER_VERSION}/${PROCESS_EXPORTER_DIR}.tar.gz
curl -fLO https://github.com/ncabatoff/process-exporter/releases/download/v${PROCESS_EXPORTER_VERSION}/checksums.txt
```

Kiểm tra checksum, phải in ra `OK`:

```bash
awk -v f="${PROCESS_EXPORTER_DIR}.tar.gz" '$2==f' checksums.txt | sha256sum -c -
```

Giải nén và cài binary:

```bash
tar -xzf ${PROCESS_EXPORTER_DIR}.tar.gz
sudo install -m 0755 ${PROCESS_EXPORTER_DIR}/process-exporter /usr/local/bin/process-exporter
/usr/local/bin/process-exporter -version
```

Tạo file cấu hình nhóm tiến trình. Nginx được tách thành nhóm riêng; các tiến trình còn lại được nhóm theo tên lệnh (`comm`):

```bash
sudo mkdir -p /etc/process-exporter
sudo tee /etc/process-exporter/config.yml > /dev/null <<'EOF'
process_names:
  - name: "nginx"
    comm:
      - nginx
  - name: "{{.Comm}}"
    cmdline:
      - '.+'
EOF
```

Tạo service systemd. process-exporter chạy bằng root để đọc được thông tin `/proc` của tiến trình thuộc user khác:

```bash
sudo tee /etc/systemd/system/process-exporter.service > /dev/null <<'EOF'
[Unit]
Description=Prometheus process-exporter 0.8.7
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
ExecStart=/usr/local/bin/process-exporter -config.path /etc/process-exporter/config.yml -web.listen-address :9256
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable process-exporter
sudo systemctl restart process-exporter
```

Kiểm tra:

```bash
systemctl is-active process-exporter
curl -s http://127.0.0.1:9256/metrics | grep -m 5 '^namedprocess_namegroup_'
```

## 6. Firewall (UFW)

Chỉ mở cổng cho đúng nguồn cần thiết. Mở SSH trước khi bật UFW để tránh tự khóa khi đang đăng nhập qua SSH.

```bash
sudo apt-get install -y ufw
sudo ufw allow OpenSSH
sudo ufw allow from 192.168.100.30 to any port 80 proto tcp
sudo ufw allow from 192.168.100.20 to any port 9100 proto tcp
sudo ufw allow from 192.168.100.20 to any port 9256 proto tcp
sudo ufw --force enable
sudo ufw status verbose
```

Nếu cần truy cập Nginx từ máy Host để kiểm tra, thêm: `sudo ufw allow from <IP_HOST> to any port 80 proto tcp`.

## 7. Kiểm tra cuối cùng

```bash
systemctl is-active nginx node_exporter process-exporter
curl -I http://127.0.0.1/
curl -s http://127.0.0.1:9100/metrics | grep -c '^node_'
curl -s http://127.0.0.1:9256/metrics | grep -c '^namedprocess_'
```

Kết quả mong đợi:

- Ba dịch vụ đều in ra `active`.
- `curl -I` trả về `HTTP/1.1 200 OK`.
- Hai lệnh `grep -c` đều trả về số lớn hơn 0.

Từ VM Monitoring (`192.168.100.20`), kiểm tra hai cổng metrics:

```bash
curl -s -o /dev/null -w "%{http_code}\n" http://192.168.100.10:9100/metrics
curl -s -o /dev/null -w "%{http_code}\n" http://192.168.100.10:9256/metrics
# Mong đợi: 200 và 200
```

Từ VM Test (`192.168.100.30`), kiểm tra HTTP:

```bash
curl -I http://192.168.100.10/
```

## 8. Ghi nhận khi bàn giao

Ghi các mục sau vào [`docs/environment.md`](environment.md):

- Phiên bản Ubuntu, Nginx, Node Exporter, process-exporter (đã nêu ở mục 0).
- Nguồn cài đặt và checksum đã kiểm tra.
- Cấu hình: `/etc/netplan/01-lab.yaml`, `/etc/process-exporter/config.yml`, hai file service systemd.
- Lệnh kiểm tra ở mục 7 và kết quả.

## 9. Xử lý lỗi thường gặp

| Triệu chứng | Nguyên nhân thường gặp | Cách kiểm tra |
|---|---|---|
| `checksum` không `OK` | Tải lỗi hoặc sai phiên bản | Tải lại file, kiểm tra biến `*_VERSION` |
| Service không `active` | Sai đường dẫn binary hoặc lỗi cú pháp | `sudo journalctl -u node_exporter -n 50` |
| Mất SSH sau khi bật UFW | Chưa mở OpenSSH | Đăng nhập lại qua console VMware, chạy `sudo ufw allow OpenSSH` |
| VM Monitoring không kết nối được 9100/9256 | Sai IP nguồn trong UFW hoặc sai VMnet | `sudo ufw status`, `ip route` |
| `nginx=1.24.0*` không có trong apt | Mirror apt khác phiên bản | `apt-cache madison nginx` |

Gỡ cài đặt để làm lại từ đầu:

```bash
sudo systemctl disable --now node_exporter process-exporter
sudo rm -f /etc/systemd/system/node_exporter.service /etc/systemd/system/process-exporter.service
sudo systemctl daemon-reload
sudo rm -f /usr/local/bin/node_exporter /usr/local/bin/process-exporter
sudo rm -rf /etc/process-exporter
sudo userdel node_exporter
```
