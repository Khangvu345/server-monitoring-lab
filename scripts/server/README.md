# Cài tự động VM Server

Script `setup-server.sh` cài và cấu hình VM Server trên Ubuntu Server 24.04.5 LTS:

| Thành phần | Phiên bản | Cổng |
|---|---|---:|
| Nginx | 1.24.0 | 80 |
| Node Exporter | 1.12.1 | 9100 |
| process-exporter | 0.8.7 | 9256 |

Script đã kiểm tra checksum của binary tải về, tạo service systemd, cấu hình UFW và chạy bước kiểm tra cuối cùng.

Script không cấu hình mạng. Hãy đặt IP tĩnh `192.168.100.10/24` theo mục 2 của [hướng dẫn thủ công](../../docs/server-manual-setup.md) trước khi chạy.

## Chạy script

Trên VM Server, lấy script từ repo rồi chạy:

```bash
git clone https://github.com/Khangvu345/server-monitoring-lab.git
cd server-monitoring-lab/scripts/server
chmod +x setup-server.sh
sudo ./setup-server.sh
```

Nếu VM Monitoring hoặc VM Test dùng IP khác, truyền biến khi chạy:

```bash
sudo MONITORING_IP=192.168.100.20 TEST_IP=192.168.100.30 ./setup-server.sh
```

| Biến | Mặc định | Ý nghĩa |
|---|---|---|
| `MONITORING_IP` | `192.168.100.20` | IP được phép scrape cổng 9100 và 9256 |
| `TEST_IP` | `192.168.100.30` | IP được phép gọi HTTP cổng 80 |

Script được thiết kế để chạy lại an toàn: binary và file cấu hình sẽ được ghi đè, user `node_exporter` chỉ được tạo nếu chưa có.

## Kết quả mong đợi

Khi thành công, script in ra `Hoàn tất.` cùng phiên bản các thành phần. Có thể kiểm tra lại thủ công:

```bash
systemctl is-active nginx node_exporter process-exporter
curl -I http://127.0.0.1/
curl -s http://127.0.0.1:9100/metrics | grep -m 3 '^node_cpu_seconds_total'
curl -s http://127.0.0.1:9256/metrics | grep -m 3 '^namedprocess_namegroup_'
```

Từ VM Monitoring, kiểm tra hai cổng metrics phải trả về `200`:

```bash
curl -s -o /dev/null -w "%{http_code}\n" http://192.168.100.10:9100/metrics
curl -s -o /dev/null -w "%{http_code}\n" http://192.168.100.10:9256/metrics
```

## Khi script lỗi

- Script dừng ngay ở bước đầu tiên lỗi và in thông báo `LỖI: ...`. Chạy lại sau khi sửa nguyên nhân là được.
- Checksum không khớp: tải lại, hoặc kiểm tra phiên bản trong biến đầu file `setup-server.sh`.
- Xem log service: `sudo journalctl -u node_exporter -n 50` hoặc `sudo journalctl -u process-exporter -n 50`.
- Nếu đang đăng nhập SSH và UFW chặn kết nối, đăng nhập lại qua console VMware rồi chạy `sudo ufw allow OpenSSH`.
- Các bước thủ công và cách gỡ cài đặt xem trong [hướng dẫn thủ công](../../docs/server-manual-setup.md).

## Lưu ý trước khi chạy

- Chỉ chạy trên VM Server dùng để lab, không chạy trên máy đang dùng cho công việc khác.
- Script ghi đè `/etc/process-exporter/config.yml` và các file service systemd nếu đã tồn tại.
- Script không lưu mật khẩu hoặc token nào.
