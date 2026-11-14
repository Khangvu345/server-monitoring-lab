# Prometheus Configuration

Thư mục `prometheus/` lưu trữ các file cấu hình phục vụ Prometheus.

## Các file cấu hình

- `prometheus.yml`: File cấu hình chính của Prometheus, khai báo các mục tiêu thu thập dữ liệu (scrape targets).
- Các rule files (nếu có): Lưu các quy tắc cảnh báo và ghi nhận dữ liệu bổ sung cho Prometheus.

## Cách sử dụng

1. Cài đặt Prometheus trên VM2 theo phiên bản đã thống nhất.
2. Tải file trực tiếp trên VM2
Mở Terminal Ubuntu trên VM2.

-Chạy lệnh:
```bash
cd ~
```

- Sau đó dùng wget (đã lấy link raw từ Github):
```bash
wget -O prometheus.yml https://raw.githubusercontent.com/Khangvu345/server-monitoring-lab/refs/heads/monitoring/configs/prometheus/prometheus.yml
```

3. Kiểm tra file vừa tải
- Chạy:
```bash
cat prometheus.yml
```

Cần thấy các job:
- job_name: "prometheus"

- job_name: "vm1-node"

- job_name: "vm1-process"

Đặc biệt kiểm tra IP:
- 192.168.100.10:9100
- 192.168.100.10:9256


4. Sao chép file `prometheus.yml` vào thư mục cấu hình:

```bash
sudo cp configs/prometheus/prometheus.yml /etc/prometheus/prometheus.yml
```

5. Kiểm tra cú pháp cấu hình:

```bash
sudo promtool check config /etc/prometheus/prometheus.yml
```

6. Nếu cấu hình hợp lệ (SUCCESS), khởi động lại Prometheus:

```bash
sudo systemctl restart prometheus
```

7. Kiểm tra trạng thái dịch vụ:

```bash
sudo systemctl status prometheus --no-pager
```

## Lưu ý

- Không commit mật khẩu, token hoặc credential thật.
- Không commit dữ liệu TSDB runtime.
- Các địa chỉ IP và port cần được điều chỉnh theo môi trường triển khai thực tế.
- Giữ nguyên các cấu hình mặc định cần thiết của Prometheus khi bổ sung scrape targets.
