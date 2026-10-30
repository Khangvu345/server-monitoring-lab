# Hướng dẫn triển khai

Tài liệu này sẽ được cập nhật theo tiến độ thực tế. Không chạy script chưa được review trên máy quan trọng.

## 1. Chuẩn bị

- Cài VMware.
- Chuẩn bị ISO Ubuntu Server cùng phiên bản cho cả nhóm.
- Tạo ba VM theo [Môi trường triển khai](docs/environment.md).
- Tạo một VMnet NAT chung trong Virtual Network Editor.
- Kết nối NIC của cả ba VM vào đúng VMnet đó.

## 2. Cài Ubuntu và cấu hình mạng

Cài Ubuntu Server trên cả ba VM. Sau khi cài, cấu hình hostname và IP theo [Thiết kế mạng](docs/network.md).

Xác minh:

```bash
hostnamectl
ip -br address
ip route
```

## 3. Cài dịch vụ theo vai trò

Các script sẽ được bổ sung tại:

- `scripts/server/`
- `scripts/monitoring/`
- `scripts/test/`

Trước khi chạy, đọc README của từng thư mục và kiểm tra phiên bản phần mềm.

## 4. Kiểm tra tích hợp

- Từ VM Test, truy cập HTTP của VM Server.
- Từ VM Monitoring, truy cập endpoint metrics của Node Exporter trên VM Server.
- Kiểm tra Prometheus target ở trạng thái UP.
- Truy cập Grafana và xác nhận datasource Prometheus.
- Chạy k6 với kịch bản kiểm thử đã được nhóm duyệt.

## 5. Ghi nhận

Lưu phiên bản phần mềm, cấu hình, lệnh kiểm tra, thời điểm triển khai và ảnh/chứng cứ phù hợp. Không đưa mật khẩu, token hoặc private key vào repository.
