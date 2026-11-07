# Cấu hình Node Exporter

Node Exporter 1.12.1 chạy trên VM Server, lắng nghe cổng 9100 và xuất metrics hệ thống (CPU, RAM, đĩa, mạng). Binary được cài vào `/usr/local/bin/node_exporter` và không commit vào repo.

## Đường dẫn trên Ubuntu

| Mục | Đường dẫn |
|---|---|
| Binary | `/usr/local/bin/node_exporter` |
| Service systemd | `/etc/systemd/system/node_exporter.service` |
| User chạy service | `node_exporter` (user hệ thống, không đăng nhập được) |

Nội dung service (đã được script `scripts/server/setup-server.sh` tạo):

```ini
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
```

Lab không cần override thêm. Nếu cần đổi cờ, sửa `ExecStart` rồi chạy:

```bash
sudo systemctl daemon-reload
sudo systemctl restart node_exporter
```

## Kiểm tra

```bash
systemctl is-active node_exporter
curl -s http://127.0.0.1:9100/metrics | grep -m 3 '^node_cpu_seconds_total'
```

Từ VM Monitoring, Prometheus scrape `192.168.100.10:9100`. Cổng này chỉ được mở cho `192.168.100.20` trong UFW.

Chi tiết cài đặt: [`docs/server-manual-setup.md`](../../docs/server-manual-setup.md).
