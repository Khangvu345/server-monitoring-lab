# Cấu hình Nginx

Nginx 1.24.0 (gói apt của Ubuntu 24.04) chạy trên VM Server, cổng 80. Lab dùng `nginx.conf` mặc định, không chỉnh sửa. Riêng site phục vụ tệp benchmark dùng file [`benchmark.conf`](benchmark.conf) trong thư mục này, được cài bởi `scripts/server/setup-server.sh`.

File `benchmark.conf` chỉ phục vụ đúng `GET /benchmark/payload.bin` với HTTP 200, không redirect, không nén (`gzip off`). Site mặc định bị gỡ để không có trang nào khác nhiễu kết quả đo.

## Đường dẫn trên Ubuntu

| Mục | Đường dẫn |
|---|---|
| File cấu hình chính | `/etc/nginx/nginx.conf` (mặc định, không sửa) |
| Site benchmark | `/etc/nginx/sites-available/benchmark`, liên kết tại `/etc/nginx/sites-enabled/benchmark` |
| Site mặc định | `/etc/nginx/sites-enabled/default` đã bị gỡ |
| Tệp phục vụ | `/var/www/benchmark/payload.bin` (65.536 byte) |
| Manifest | `/etc/benchmark/manifest.txt` (kèm SHA-256 và cấu hình VM) |
| Log truy cập / lỗi | `/var/log/nginx/access.log`, `/var/log/nginx/error.log` |

## Kiểm tra cú pháp và áp dụng

```bash
sudo nginx -t
sudo systemctl reload nginx
```

`nginx -t` phải in ra `syntax is ok` và `test is successful` trước khi reload.

## Kiểm tra phục vụ HTTP

```bash
curl -I http://127.0.0.1/benchmark/payload.bin
# HTTP/1.1 200 OK

curl -sS -o /tmp/check.bin -w "HTTP %{http_code} | bytes %{size_download} | redirect %{num_redirects}\n" \
  -H "Accept-Encoding: identity" http://127.0.0.1/benchmark/payload.bin
sha256sum /tmp/check.bin
# HTTP 200 | bytes 65536 | redirect 0
# 7daca2095d0438260fa849183dfc67faa459fdf4936e1bc91eec6b281b27e4c2
```

Từ VM Test, kiểm tra cổng 80 của VM Server (`192.168.100.10`) đã được firewall mở đúng nguồn:

```bash
curl -I -H "Accept-Encoding: identity" http://192.168.100.10/benchmark/payload.bin
```

Chi tiết cài đặt và firewall: [`docs/server-manual-setup.md`](../../docs/server-manual-setup.md) và [`scripts/server/`](../../scripts/server/README.md).
