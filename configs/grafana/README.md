Đặt provisioning datasource/dashboard và dashboard JSON tại đây. Không commit credential thật.

Thư mục `grafana/` lưu trữ các cấu hình:

- `provisioning/datasources/prometheus.yml`:
  Khai báo Prometheus Data Source.
- `provisioning/dashboards/dashboard.yml`:
  Cấu hình tự động nạp Dashboard.
- `dashboards/vm-server-monitoring.json`:
  Dashboard giám sát hệ thống VM.

Dashboard hỗ trợ theo dõi:
- CPU Usage
- Memory Usage
- Network Transmit
- Process Count
- Disk Read
- Disk Write
