# Configurations

Lưu các file cấu hình dịch vụ được quản lý bằng Git:

- `nginx/`: cấu hình Nginx.
- `node-exporter/`: tham số/service override nếu cần.
- `prometheus/`: `prometheus.yml` và rule files.
- `grafana/`: provisioning datasource/dashboard và dashboard JSON.

Không lưu secret hoặc credential thật. Dùng file mẫu và biến môi trường nếu cần thông tin nhạy cảm.
