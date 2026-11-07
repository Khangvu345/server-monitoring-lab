# Cấu hình process-exporter

process-exporter 0.8.7 chạy trên VM Server, lắng nghe cổng 9256 và xuất metrics theo nhóm tiến trình (`namedprocess_namegroup_*`). Node Exporter không có số liệu này nên đây là thành phần bắt buộc của đề tài. Binary được cài vào `/usr/local/bin/process-exporter` và không commit vào repo.

## Đường dẫn trên Ubuntu

| Mục | Đường dẫn |
|---|---|
| Binary | `/usr/local/bin/process-exporter` |
| File cấu hình nhóm tiến trình | `/etc/process-exporter/config.yml` |
| Service systemd | `/etc/systemd/system/process-exporter.service` |

## File cấu hình nhóm tiến trình

Nội dung `/etc/process-exporter/config.yml`:

```yaml
process_names:
  - name: "nginx"
    comm:
      - nginx
  - name: "{{.Comm}}"
    cmdline:
      - '.+'
```

- Nhóm `nginx` gom master và các worker của Nginx thành một nhóm, để thấy riêng Nginx tốn bao nhiêu CPU/RAM.
- Nhóm thứ hai gom các tiến trình còn lại theo tên lệnh (`{{.Comm}}`).
- Quy tắc được đọc theo thứ tự từ trên xuống, tiến trình khớp quy tắc đầu tiên sẽ không khớp quy tắc sau.

## Service systemd

Service chạy bằng root để đọc được `/proc` của tiến trình thuộc user khác:

```ini
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
```

Sau khi sửa `config.yml`, khởi động lại service:

```bash
sudo systemctl restart process-exporter
```

## Kiểm tra

```bash
systemctl is-active process-exporter
curl -s http://127.0.0.1:9256/metrics | grep -m 5 '^namedprocess_namegroup_'
```

Nếu lệnh thứ hai không in ra dòng nào, kiểm tra log bằng `sudo journalctl -u process-exporter -n 50` và cú pháp YAML trong `config.yml`.

Từ VM Monitoring, Prometheus scrape `192.168.100.10:9256`. Cổng này chỉ được mở cho `192.168.100.20` trong UFW.

Chi tiết cài đặt: [`docs/server-manual-setup.md`](../../docs/server-manual-setup.md).
