# Grafana Configuration

Thư mục `grafana/` lưu trữ các cấu hình và Dashboard phục vụ giám sát hệ thống.

## Dashboard

- `dashboards/vm-server-monitoring.json`: Dashboard giám sát hệ thống VM1, được xây dựng bằng Grafana và sử dụng Prometheus làm Data Source.

Dashboard hỗ trợ theo dõi các chỉ số:

- CPU Usage
- RAM Usage
- Disk Usage
- Network Receive
- Network Transmit
- Process Count
- Disk Read / Write
- RAM Available
- Disk Read / Write IOPS
- Nginx CPU Usage
- Nginx RAM Usage

## Cách sử dụng

1. Cài đặt và khởi động Grafana.
2. Thêm Prometheus làm Data Source.
3. Truy cập mục **Dashboards → New → Import**.
4. Chọn file `dashboards/vm-server-monitoring.json`.
5. Chọn Data Source Prometheus nếu được yêu cầu.
6. Nhấn Import để hoàn tất.

Dashboard được import thủ công từ file JSON, không sử dụng cơ chế provisioning tự động.

## Lưu ý

- Không commit mật khẩu, token hoặc credential thật.
- Khi thay đổi Dashboard, cập nhật lại file JSON tương ứng trong repository.
