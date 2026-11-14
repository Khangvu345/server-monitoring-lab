# Configurations

Lưu các file cấu hình dịch vụ được quản lý bằng Git:

- `nginx/`: cấu hình Nginx.
- `node-exporter/`: tham số/service override nếu cần.
- `prometheus/`: `prometheus.yml` và rule files.
- `grafana/dashboards`: dashboard JSON để tải về import trên VM2 "http://192.168.100.20:3000/".

Không lưu secret hoặc credential thật. Dùng file mẫu và biến môi trường nếu cần thông tin nhạy cảm.
