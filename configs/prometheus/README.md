Đặt prometheus.yml và rule files tại đây. Không commit dữ liệu TSDB runtime.
Thư mục `prometheus/` lưu trữ:

- `prometheus.yml`: Cấu hình Prometheus và các mục tiêu thu thập dữ liệu.
- `rules/`: Lưu các file cảnh báo và quy tắc giám sát (nếu có).

- Không commit mật khẩu, token hoặc credential thật.
- Không commit dữ liệu TSDB runtime.
- Các địa chỉ IP và port cần được điều chỉnh theo môi trường triển khai thực tế.
