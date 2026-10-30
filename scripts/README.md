# Scripts

Các script được chia theo vai trò VM:

- `common/`: thiết lập nền dùng chung (sẽ bổ sung sau khi nhóm thống nhất).
- `server/`: cài đặt và cấu hình Nginx, Node Exporter, process-exporter.
- `monitoring/`: cài đặt và cấu hình Prometheus, Grafana.
- `test/`: cài đặt k6 và tiện ích kiểm thử.

## Quy ước

- Script phải kiểm tra lỗi và dừng khi lệnh quan trọng thất bại.
- Ghi rõ phiên bản phần mềm; không tự động cài `latest`.
- Có thể chạy lại an toàn trong phạm vi đã thiết kế.
- Không chứa mật khẩu, token hoặc private key.
- Cung cấp lệnh xác minh sau cài đặt.
- Mỗi script cần có hướng dẫn sử dụng và điều kiện tiên quyết.
