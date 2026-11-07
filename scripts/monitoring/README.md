# CẤU HÌNH VM2 MONITORING (thủ công)

## 1. Giới thiệu

Tài liệu này hướng dẫn cài đặt và cấu hình máy ảo VM2 Monitoring trong hệ thống giám sát Server.

VM2 sử dụng hai thành phần chính:

- **Prometheus:** Thu thập, lưu trữ và truy vấn dữ liệu giám sát từ các máy chủ.
- **Grafana:** Kết nối với Prometheus để trực quan hóa dữ liệu thông qua Dashboard.

VM2 chịu trách nhiệm thu thập dữ liệu tài nguyên từ VM1 thông qua Node Exporter và Process Exporter đã được cài đặt trên VM1.

### 1.1. Thông tin VM2

| Thông tin | Giá trị |
|---|---|
| Hệ điều hành | Ubuntu Server 24.04 LTS |
| Địa chỉ IP | 192.168.100.20 |
| Prometheus | Port 9090 |
| Grafana | Port 3000 |
| Node Exporter trên VM1 | Port 9100 |
| Process Exporter trên VM1 | Port 9256 |

### 1.2. Mô hình hoạt động

```text
              VM1 - SERVER
             192.168.100.10
                    |
          +---------+---------+
          |                   |
     Node Exporter       Process Exporter
       Port 9100            Port 9256
          |                   |
          +---------+---------+
                    |
                    | HTTP /metrics
                    |
              VM2 - MONITORING
             192.168.100.20
                    |
               Prometheus
                Port 9090
                    |
                    |
                 Grafana
                Port 3000
                    |
                    |
              Dashboard
          VM1 Server Monitoring
```

**Nguyên lý hoạt động:**

1. Node Exporter cung cấp thông tin CPU, RAM, ổ đĩa và mạng của VM1.
2. Process Exporter cung cấp thông tin tài nguyên của các nhóm tiến trình, trong đó có Nginx.
3. Prometheus trên VM2 định kỳ truy cập hai endpoint để thu thập dữ liệu.
4. Grafana kết nối với Prometheus để truy vấn và hiển thị các đại lượng giám sát.

---

## 2. Cài đặt và kiểm tra Ubuntu Server

### 2.1. Cài đặt hệ điều hành

Cài đặt Ubuntu Server 24.04 LTS trên máy ảo VM2.

Sau khi cài đặt hoàn tất, khởi động lại máy:

```bash
sudo reboot
```

Địa chỉ IP VM2 sử dụng trong hệ thống:

```text
192.168.100.20
```

### 2.2. Kiểm tra phiên bản hệ điều hành

```bash
lsb_release -a
```

Kết quả cần xác nhận Ubuntu 24.04 LTS.

### 2.3. Kiểm tra địa chỉ IP và card mạng

```bash
ip -br addr
```

Kiểm tra bảng định tuyến:

```bash
ip route
```

Đảm bảo máy ảo có địa chỉ IP đúng và card mạng đang hoạt động.

### 2.4. Kiểm tra kết nối Internet

Kiểm tra kết nối bằng địa chỉ IP:

```bash
ping -c 4 8.8.8.8
```

Kiểm tra phân giải tên miền:

```bash
ping -c 4 google.com
```

Kết quả:

- Nếu cả hai lệnh thành công: kết nối Internet và DNS cơ bản hoạt động.
- Nếu ping IP thành công nhưng ping tên miền thất bại: kiểm tra DNS.
- Nếu cả hai thất bại: kiểm tra cấu hình mạng VMware NAT.

### 2.5. Cập nhật danh sách gói

```bash
sudo apt update
```

---

## 3. Cài đặt Prometheus trên VM2

### 3.1. Cài đặt

Chạy lệnh:

```bash
sudo apt install -y prometheus
```

### 3.2. Kiểm tra phiên bản

```bash
prometheus --version
```

Ghi nhận phiên bản thực tế để sử dụng thống nhất trong báo cáo và quá trình triển khai.

### 3.3. Khởi động và bật tự động

```bash
sudo systemctl enable --now prometheus
```

Kiểm tra trạng thái:

```bash
sudo systemctl status prometheus --no-pager
```

Nếu hiển thị:

```text
Active: active (running)
```

thì Prometheus đang hoạt động.

### 3.4. Kiểm tra cổng

```bash
sudo ss -lntp | grep 9090
```

Prometheus mặc định sử dụng cổng 9090.

### 3.5. Kiểm tra Prometheus bằng HTTP

```bash
curl -s http://localhost:9090/-/ready
```

Kết quả mong đợi:

```text
Prometheus Server is Ready.
```

Kiểm tra thông tin phiên bản:

```bash
curl -s http://localhost:9090/api/v1/status/buildinfo
```

Nếu trả về dữ liệu JSON chứa thông tin phiên bản, Prometheus đã phản hồi API thành công.

### 3.6. Vị trí file cấu hình

File cấu hình chính:

```text
/etc/prometheus/prometheus.yml
```

File thực thi:

```text
/usr/bin/prometheus
```

Dịch vụ systemd:

```text
prometheus.service
```

---

## 4. Cài đặt Grafana trên VM2

### 4.1. Cài đặt các công cụ cần thiết

```bash
sudo apt-get install -y apt-transport-https software-properties-common wget
```

### 4.2. Thêm khóa xác thực Grafana

Tạo thư mục lưu khóa:

```bash
sudo mkdir -p /etc/apt/keyrings
```

Tải khóa xác thực:

```bash
sudo wget -q -O /etc/apt/keyrings/grafana.asc https://apt.grafana.com/gpg.key
```

### 4.3. Thêm kho Grafana

```bash
echo "deb [signed-by=/etc/apt/keyrings/grafana.asc] https://apt.grafana.com stable main" | sudo tee /etc/apt/sources.list.d/grafana.list
```

### 4.4. Cài đặt Grafana

```bash
sudo apt update
sudo apt install -y grafana
```

Kiểm tra phiên bản:

```bash
grafana --version
```

Ghi nhận phiên bản thực tế sau khi cài đặt.

### 4.5. Khởi động và bật tự động

```bash
sudo systemctl enable --now grafana-server
```

Kiểm tra trạng thái:

```bash
sudo systemctl status grafana-server --no-pager
```

Nếu hiển thị:

```text
Active: active (running)
```

thì Grafana đang hoạt động.

### 4.6. Kiểm tra cổng

```bash
sudo ss -lntp | grep 3000
```

Grafana mặc định sử dụng cổng 3000.

### 4.7. Truy cập Grafana

Mở trình duyệt trên máy host hoặc máy tính trong cùng mạng:

```text
http://192.168.100.20:3000
```

Thông tin đăng nhập mặc định:

- Username: `admin`
- Password: `admin`

Hệ thống thường yêu cầu đổi mật khẩu sau lần đăng nhập đầu tiên. Cần đặt mật khẩu riêng và không đưa mật khẩu thực tế vào tài liệu công khai.

### 4.8. Vị trí file và dịch vụ Grafana

| Thành phần | Đường dẫn |
|---|---|
| File cấu hình | `/etc/grafana/grafana.ini` |
| Thư mục dữ liệu mặc định | `/var/lib/grafana` |
| Thư mục log | `/var/log/grafana` |
| Dịch vụ systemd | `grafana-server.service` |

---

## 5. Cấu hình Prometheus thu thập dữ liệu từ VM1

Đây là bước quan trọng nhất trong phần cấu hình Monitoring trên VM2.

Mục tiêu là cấu hình Prometheus thu thập dữ liệu thực tế từ hai exporter trên VM1.

### 5.1. Kiểm tra kết nối đến VM1

Node Exporter và Process Exporter được cài đặt trên VM1.

Từ Terminal VM2, kiểm tra Node Exporter:

```bash
curl -s -o /dev/null -w "%{http_code}\n" http://192.168.100.10:9100/metrics
```

Kiểm tra Process Exporter:

```bash
curl -s -o /dev/null -w "%{http_code}\n" http://192.168.100.10:9256/metrics
```

Kết quả mong đợi:

```text
200
200
```

Nếu cả hai trả về HTTP 200, VM2 đã truy cập được hai endpoint cung cấp metric trên VM1.

Nếu không thành công, cần kiểm tra IP, trạng thái dịch vụ exporter và firewall trên VM1.

### 5.2. Sao lưu file cấu hình

Trước khi chỉnh sửa, tạo bản sao lưu:

```bash
sudo cp /etc/prometheus/prometheus.yml /etc/prometheus/prometheus.yml.bak
```

### 5.3. Mở file cấu hình

```bash
sudo nano /etc/prometheus/prometheus.yml
```

File cấu hình nằm tại:

```text
/etc/prometheus/prometheus.yml
```

### 5.4. Cấu hình Prometheus

Tham khảo cấu hình sau:

```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

  external_labels:
    monitor: 'vm2-monitoring'

alerting:
  alertmanagers:
    - static_configs:
        - targets: ['localhost:9093']

rule_files
