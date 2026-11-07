# Cài tự động VM Server

Script `setup-server.sh` cài và cấu hình VM Server trên Ubuntu Server 24.04.5 LTS:

| Thành phần | Phiên bản | Cổng |
|---|---|---:|
| Nginx | 1.24.0 | 80 |
| Node Exporter | 1.12.1 | 9100 |
| process-exporter | 0.8.7 | 9256 |

Script đã kiểm tra checksum của binary tải về, tạo service systemd, cấu hình UFW và chạy bước kiểm tra cuối cùng.

Script cũng tạo tệp benchmark `/var/www/benchmark/payload.bin` (65.536 byte, SHA-256 `7daca209...e4c2`), ghi manifest vào `/etc/benchmark/manifest.txt` và cài site Nginx từ [`configs/nginx/benchmark.conf`](../../configs/nginx/benchmark.conf). Bước kiểm tra cuối cùng xác nhận `GET /benchmark/payload.bin` trả về HTTP 200, đủ 65.536 byte và đúng mã băm.

Script không cấu hình mạng. Hãy đặt IP tĩnh `192.168.100.10/24` theo mục 2 của [hướng dẫn thủ công](../../docs/server-manual-setup.md) trước khi chạy.

## Chạy script

Trên VM Server, lấy script từ repo rồi chạy:

```bash
git clone https://github.com/Khangvu345/server-monitoring-lab.git
cd server-monitoring-lab/scripts/server
chmod +x setup-server.sh
sudo ./setup-server.sh
```

Script phải chạy từ thư mục `scripts/server` trong repo, vì nó đọc file `configs/nginx/benchmark.conf` ở vị trí tương đối.

Nếu VM Monitoring hoặc VM Test dùng IP khác, truyền biến khi chạy:

```bash
sudo MONITORING_IP=192.168.100.20 TEST_IP=192.168.100.30 ./setup-server.sh
```

| Biến | Mặc định | Ý nghĩa |
|---|---|---|
| `MONITORING_IP` | `192.168.100.20` | IP được phép scrape cổng 9100 và 9256 |
| `TEST_IP` | `192.168.100.30` | IP được phép gọi HTTP cổng 80 |

Script được thiết kế để chạy lại an toàn: binary và file cấu hình sẽ được ghi đè, user `node_exporter` chỉ được tạo nếu chưa có.

## Tệp benchmark

Script tạo `/var/www/benchmark/payload.bin` và cấu hình Nginx để phục vụ tệp này. Kiểm tra thủ công sau khi cài:

```bash
stat -c %s /var/www/benchmark/payload.bin
# 65536

sha256sum /var/www/benchmark/payload.bin
# 7daca2095d0438260fa849183dfc67faa459fdf4936e1bc91eec6b281b27e4c2

curl -sS -o /tmp/check.bin -w "HTTP %{http_code} | bytes %{size_download} | redirect %{num_redirects}\n" \
  -H "Accept-Encoding: identity" http://127.0.0.1/benchmark/payload.bin
# HTTP 200 | bytes 65536 | redirect 0
```

Từ VM Test, lấy được cùng kết quả với `http://192.168.100.10/benchmark/payload.bin`. Manifest ghi tại `/etc/benchmark/manifest.txt`, cần gửi cho nhóm cùng SHA-256 và IP VM Server.

Nếu cần chạy lại từ đầu, script ghi đè payload và manifest nhưng không xóa tệp cũ khác.

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
