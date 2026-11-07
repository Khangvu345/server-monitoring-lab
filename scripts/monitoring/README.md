# HƯỚNG DẪN CÀI ĐẶT VÀ CẤU HÌNH VM2 – MONITORING (THỦ CÔNG)

Tài liệu này hướng dẫn cài đặt và cấu hình **Prometheus, Grafana trên VM2**, kết nối với các Exporter trên VM1 và tạo Dashboard giám sát.

> **Lưu ý:** Các phiên bản phần mềm trong tài liệu được giữ cố định theo thống nhất của nhóm. Không tự ý đổi phiên bản khi thực hiện.

## 1. Thông tin môi trường VM2

| Thành phần | Giá trị |
|---|---|
| Hệ điều hành | Ubuntu Server 24.04 LTS |
| Địa chỉ IP VM2 | `192.168.100.20` |
| Prometheus | `2.45.3` |
| Grafana | `13.2.4` |
| Node Exporter trên VM1 | `1.12.1` |
| process-exporter trên VM1 | `0.8.7` |
| Cổng Prometheus | `9090` |
| Cổng Grafana | `3000` |
| Cổng Node Exporter | `9100` |
| Cổng process-exporter | `9256` |

Địa chỉ VM1 được sử dụng trong tài liệu là `192.168.100.10`.

## 2. Kiểm tra hệ điều hành và kết nối mạng

### Bước 2.1 – Kiểm tra phiên bản Ubuntu

```bash
lsb_release -a
```

Kết quả cần xác nhận Ubuntu Server 24.04 LTS.

### Bước 2.2 – Kiểm tra địa chỉ IP và card mạng

```bash
ip -br addr
ip route
```

Đảm bảo VM2 sử dụng đúng địa chỉ IP `192.168.100.20`.

### Bước 2.3 – Kiểm tra kết nối Internet và DNS

```bash
ping -c 4 8.8.8.8
ping -c 4 google.com
```

- Nếu cả hai lệnh thành công: kết nối Internet và phân giải DNS cơ bản hoạt động.
- Nếu ping IP thành công nhưng ping tên miền thất bại: kiểm tra DNS.
- Nếu cả hai thất bại: kiểm tra cấu hình mạng VMnet NAT trước khi tiếp tục.

### Bước 2.4 – Cập nhật danh sách gói

```bash
sudo apt update
```

## 3. Cài đặt Prometheus trên VM2

### Bước 3.1 – Cài đặt

```bash
sudo apt install -y prometheus
```

### Bước 3.2 – Kiểm tra phiên bản

```bash
prometheus --version
```

**Phiên bản yêu cầu: `2.45.3`.**

Nếu phiên bản hiển thị không đúng, không tự ý thay đổi sang phiên bản khác. Kiểm tra nguồn gói và trao đổi với nhóm trước khi tiếp tục.

### Bước 3.3 – Kiểm tra và bật dịch vụ

```bash
sudo systemctl status prometheus --no-pager
```

Nếu dịch vụ chưa chạy, bật dịch vụ và thiết lập tự khởi động:

```bash
sudo systemctl enable --now prometheus
```

Kiểm tra lại:

```bash
sudo systemctl status prometheus --no-pager
```

Trạng thái mong đợi: `active (running)`.

### Bước 3.4 – Kiểm tra cổng và API

```bash
sudo ss -lntp | grep 9090
```

Kiểm tra Prometheus đã sẵn sàng:

```bash
curl -s http://localhost:9090/-/ready
```

Kết quả mong đợi:

```text
Prometheus Server is Ready.
```

Kiểm tra thông tin phiên bản qua API:

```bash
curl -s http://localhost:9090/api/v1/status/buildinfo
```

Nếu trả về dữ liệu JSON chứa thông tin build và phiên bản Prometheus, dịch vụ đã phản hồi.

Có thể truy cập giao diện từ máy host:

```text
http://192.168.100.20:9090
```

## 4. Cài đặt Grafana trên VM2

### Bước 4.1 – Cài các gói cần thiết

```bash
sudo apt-get install -y apt-transport-https software-properties-common wget
```

Các phiên bản gói đã thống nhất:

| Gói | Phiên bản |
|---|---|
| apt-transport-https | `2.8.3` |
| software-properties-common | `0.99.49.4` |
| wget | `1.21.4-1ubuntu4.5` |

Có thể kiểm tra phiên bản gói bằng:

```bash
apt policy apt-transport-https software-properties-common wget
```

### Bước 4.2 – Thêm khóa xác thực và kho Grafana

Tạo thư mục lưu khóa:

```bash
sudo mkdir -p /etc/apt/keyrings
```

Tải khóa xác thực:

```bash
sudo wget -q -O /etc/apt/keyrings/grafana.asc https://apt.grafana.com/gpg.key
```

Thêm kho Grafana:

```bash
echo "deb [signed-by=/etc/apt/keyrings/grafana.asc] https://apt.grafana.com stable main" | sudo tee /etc/apt/sources.list.d/grafana.list
```

### Bước 4.3 – Cập nhật kho và cài Grafana

```bash
sudo apt update
sudo apt install -y grafana
```

Kiểm tra phiên bản:

```bash
grafana --version
```

**Phiên bản yêu cầu: `13.2.4`.**

Nếu phiên bản không đúng, dừng lại để kiểm tra gói trong kho và thống nhất với nhóm; không tự ý sử dụng phiên bản khác.

### Bước 4.4 – Khởi động Grafana

```bash
sudo systemctl enable --now grafana-server
```

Kiểm tra trạng thái:

```bash
sudo systemctl status grafana-server --no-pager
```

Trạng thái mong đợi: `active (running)`.

Kiểm tra cổng:

```bash
sudo ss -lntp | grep 3000
```

Truy cập Grafana từ máy host:

```text
http://192.168.100.20:3000
```

Thông tin đăng nhập lần đầu thường là:

- Username: `admin`
- Password: `admin`

Grafana thường yêu cầu đổi mật khẩu sau lần đăng nhập đầu tiên. Hãy đặt mật khẩu riêng và không ghi mật khẩu thật vào tài liệu chung của nhóm.

## 5. Kết nối Prometheus với VM1

Đây là bước giúp Prometheus thu thập dữ liệu thực tế từ VM1 thay vì chỉ chạy giao diện.

Mục tiêu: VM2 thu thập được các chỉ số CPU, RAM, ổ đĩa, mạng và tiến trình từ VM1.

### Bước 5.1 – Xác nhận Exporter trên VM1

Thành viên phụ trách VM1 cần cài đặt và bật các dịch vụ sau:

| Dịch vụ | Phiên bản | Cổng |
|---|---:|---:|
| Node Exporter | `1.12.1` | `9100` |
| process-exporter | `0.8.7` | `9256` |

Không cài lại các Exporter trên VM2. Các dịch vụ này chạy trên VM1.

### Bước 5.2 – Kiểm tra kết nối từ VM2

Trên terminal VM2, kiểm tra Node Exporter:

```bash
curl -s -o /dev/null -w "%{http_code}\n" http://192.168.100.10:9100/metrics
```

Kiểm tra process-exporter:

```bash
curl -s -o /dev/null -w "%{http_code}\n" http://192.168.100.10:9256/metrics
```

Kết quả mong đợi:

```text
200
200
```

Nếu cả hai lệnh đều trả về `200`, VM2 đã truy cập được hai nguồn dữ liệu trên VM1.

Nếu không thành công, kiểm tra lại IP, trạng thái dịch vụ Exporter và firewall trên VM1 trước khi sửa cấu hình Prometheus.

### Bước 5.3 – Khai báo VM1 trong Prometheus

Sao lưu cấu hình hiện tại:

```bash
sudo cp /etc/prometheus/prometheus.yml /etc/prometheus/prometheus.yml.bak
```

Mở file cấu hình:

```bash
sudo nano /etc/prometheus/prometheus.yml
```

Tìm phần `scrape_configs:`. Thêm hai job dưới đây vào bên trong danh sách `scrape_configs`, đồng thời **giữ nguyên job mặc định đang có**:

```yaml
  - job_name: "vm1-node"
    static_configs:
      - targets: ["192.168.100.10:9100"]

  - job_name: "vm1-process"
    static_configs:
      - targets: ["192.168.100.10:9256"]
```

Lưu ý:

- Không tạo thêm một mục `scrape_configs:` thứ hai.
- Chú ý thụt lề YAML.
- Không xóa cấu hình job mặc định.
- Nếu IP VM1 thay đổi, cập nhật lại địa chỉ trong `targets`.

Lưu file bằng `Ctrl + O` → `Enter` → `Ctrl + X`.

### Bước 5.4 – Kiểm tra và nạp lại cấu hình

Kiểm tra cú pháp:

```bash
sudo promtool check config /etc/prometheus/prometheus.yml
```

Nếu cấu hình hợp lệ, khởi động lại Prometheus:

```bash
sudo systemctl restart prometheus
```

Kiểm tra dịch vụ:

```bash
sudo systemctl status prometheus --no-pager
```

Mở trang Targets:

```text
http://192.168.100.20:9090/targets
```

Hai target `vm1-node` và `vm1-process` cần có trạng thái `UP`.

Nếu target `DOWN`, kiểm tra địa chỉ IP, cổng Exporter, kết nối mạng và firewall trên VM1.

## 6. Kết nối Grafana với Prometheus

Chỉ thực hiện bước này sau khi Prometheus hoạt động và các target cần thiết đã ở trạng thái `UP`.

### Bước 6.1 – Thêm Data Source

Truy cập:

```text
http://192.168.100.20:3000
```

Đăng nhập Grafana và thực hiện:

1. Chọn **Connections**.
2. Chọn **Data sources**.
3. Chọn **Add data source**.
4. Chọn **Prometheus**.
5. Nhập URL:

```text
http://localhost:9090
```

Vì Prometheus và Grafana cùng chạy trên VM2 nên sử dụng `localhost` là phù hợp.

6. Nhấn **Save & test**.

Nếu Grafana thông báo kết nối thành công, Data Source đã được cấu hình.

### Bước 6.2 – Kiểm tra dữ liệu trong Explore

1. Mở **Explore**.
2. Chọn Data Source là Prometheus.
3. Nhập từng truy vấn PromQL để kiểm tra dữ liệu.

| Chỉ số | PromQL |
|---|---|
| CPU | `rate(node_cpu_seconds_total{mode!="idle"}[5m])` |
| RAM sử dụng (%) | `100 * (1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)` |
| Disk | `node_filesystem_size_bytes - node_filesystem_avail_bytes` |
| Network nhận | `rate(node_network_receive_bytes_total[5m])` |
| Network gửi | `rate(node_network_transmit_bytes_total[5m])` |

Kiểm tra thêm process-exporter:

```promql
namedprocess_namegroup_num_procs
```

Nếu các truy vấn trả về dữ liệu, có thể bắt đầu tạo Dashboard.

## 7. Tạo Dashboard giám sát VM1

### Bước 7.1 – Tạo Dashboard mới

Truy cập Grafana:

```text
http://192.168.100.20:3000
```

Thực hiện:

1. Mở **Dashboards**.
2. Chọn **New** → **New dashboard**.
3. Chọn **Add visualization** hoặc tạo Panel mới.
4. Chọn Data Source là **Prometheus**.
5. Nhập truy vấn PromQL tương ứng.
6. Chọn kiểu hiển thị, đặt tên và cấu hình đơn vị.
7. Nhấn **Apply** để thêm Panel vào Dashboard.

Sau khi nhập truy vấn, nếu biểu đồ chưa cập nhật, nhấn **Run queries**.

Các Panel dưới đây sử dụng IP VM1 là `192.168.100.10`.

### Panel 1 – CPU Usage (%)

- **Title:** `VM1 - CPU Usage (%)`
- **Visualization:** Time series
- **Data source:** Prometheus

PromQL:

```promql
100 * (1 - avg by (instance) (
  rate(node_cpu_seconds_total{
    instance="192.168.100.10:9100",
    mode="idle"
  }[1m])
))
```

Truy vấn tính phần trăm CPU đang sử dụng, không tính thời gian CPU ở trạng thái idle.

### Panel 2 – RAM Usage (%)

- **Title:** `VM1 - RAM Usage (%)`
- **Visualization:** Time series

PromQL:

```promql
100 * (
  1 -
  node_memory_MemAvailable_bytes{
    instance="192.168.100.10:9100"
  }
  /
  node_memory_MemTotal_bytes{
    instance="192.168.100.10:9100"
  }
)
```

Standard options:

- Unit: `Percent (0-100)`
- Min: `0`
- Max: `100`

### Panel 3 – Disk Usage (%)

- **Title:** `VM1 - Disk Usage (%)`
- **Visualization:** Time series

PromQL:

```promql
100 * (
  1 -
  node_filesystem_avail_bytes{
    instance="192.168.100.10:9100",
    mountpoint="/",
    fstype!=""
  }
  /
  node_filesystem_size_bytes{
    instance="192.168.100.10:9100",
    mountpoint="/",
    fstype!=""
  }
)
```

### Panel 4 – Network Receive

- **Title:** `VM1 - Network Receive`
- **Visualization:** Time series

PromQL:

```promql
rate(node_network_receive_bytes_total{
  instance="192.168.100.10:9100",
  device="ens33"
}[1m])
```

Unit: `bytes/sec (B/s)`.

### Panel 5 – Network Transmit

- **Title:** `VM1 - Network Transmit`
- **Visualization:** Time series

PromQL:

```promql
rate(node_network_transmit_bytes_total{
  instance="192.168.100.10:9100",
  device="ens33"
}[1m])
```

Unit: `bytes/sec (B/s)`.

**Lưu ý:** `ens33` chỉ là tên card mạng được dùng trong ví dụ. Nếu card mạng VM1 có tên khác, thay bằng tên thực tế lấy từ lệnh `ip -br addr` trên VM1.

### Panel 6 – Process Count

- **Title:** `VM1 - Process Count`
- **Visualization:** Time series

PromQL:

```promql
namedprocess_namegroup_num_procs{
  instance="192.168.100.10:9256"
}
```

Panel giúp theo dõi số lượng tiến trình theo từng nhóm mà process-exporter ghi nhận.

### Panel 7 – Disk Read

PromQL:

```promql
rate(node_disk_read_bytes_total{
  instance="192.168.100.10:9100",
  device="sda"
}[1m])
```

- **Title:** `VM1 - Disk Read`
- **Visualization:** Time series
- **Unit:** `bytes/sec (B/s)`

### Panel 8 – Disk Write

PromQL:

```promql
rate(node_disk_written_bytes_total{
  instance="192.168.100.10:9100",
  device="sda"
}[1m])
```

- **Title:** `VM1 - Disk Write`
- **Visualization:** Time series
- **Unit:** `bytes/sec (B/s)`

**Lưu ý:** `sda` chỉ là tên ổ đĩa ví dụ. Kiểm tra tên ổ đĩa thực tế trên VM1 bằng:

```bash
lsblk
```

Nếu tên ổ đĩa khác, thay `sda` bằng tên tương ứng.

### Panel 9 – RAM Available

PromQL:

```promql
node_memory_MemAvailable_bytes{
  instance="192.168.100.10:9100"
} / 1024 / 1024
```

Cấu hình:

| Thuộc tính | Giá trị |
|---|---|
| Title | `VM1 - RAM Available` |
| Visualization | Stat |
| Unit | Data → mebibytes (MiB) |
| Decimals | `2` |
| Calculation | Last |

Kết quả là lượng RAM còn khả dụng của VM1 theo MiB.

`MemAvailable` là lượng RAM hệ thống ước tính có thể cấp phát cho ứng dụng mà không cần swap; không đơn giản chỉ là RAM chưa sử dụng.

### Panel 10 – Disk IOPS

**10.1 – Disk Read IOPS**

PromQL:

```promql
sum(
  rate(node_disk_reads_completed_total{
    instance="192.168.100.10:9100",
    device!~"loop.*|ram.*"
  }[1m])
)
```

Cấu hình:

| Thuộc tính | Giá trị |
|---|---|
| Title | `VM1 - Disk Read IOPS` |
| Visualization | Time series |
| Unit | Throughput → ops/sec |
| Legend | Read IOPS |
| Min | `0` |

**10.2 – Disk Write IOPS**

PromQL:

```promql
sum(
  rate(node_disk_writes_completed_total{
    instance="192.168.100.10:9100",
    device!~"loop.*|ram.*"
  }[1m])
)
```

Cấu hình:

| Thuộc tính | Giá trị |
|---|---|
| Title | `VM1 - Disk Write IOPS` |
| Visualization | Time series |
| Unit | Throughput → ops/sec |
| Legend | Write IOPS |
| Min | `0` |

Các truy vấn trên thể hiện số thao tác đọc/ghi ổ đĩa mỗi giây (IOPS).

### Panel 11 – Nginx CPU Usage (%)

PromQL:

```promql
100 * sum(
  rate(namedprocess_namegroup_cpu_seconds_total{
    instance="192.168.100.10:9256",
    groupname="nginx"
  }[1m])
)
```

Cấu hình:

- **Title:** `VM1 - Nginx CPU Usage`
- **Visualization:** Time series
- **Unit:** Percent (0-100)
- **Legend:** Nginx CPU

CPU của Nginx có thể vượt 100% nếu tiến trình sử dụng nhiều hơn một CPU core. Đây là cách tính tổng CPU theo số core, không nhất thiết là lỗi.

### Panel 12 – Nginx RAM (MiB)

PromQL:

```promql
sum(
  namedprocess_namegroup_memory_bytes{
    instance="192.168.100.10:9256",
    groupname="nginx",
    memtype="resident"
  }
) / 1024 / 1024
```

Cấu hình:

- **Title:** `VM1 - Nginx RAM`
- **Visualization:** Stat
- **Unit:** Data → mebibytes (MiB)
- **Calculation:** Last

Nếu Panel Nginx không có dữ liệu, kiểm tra process-exporter có nhận diện đúng nhóm tiến trình Nginx hay không. Tên nhãn và nhóm phải khớp với dữ liệu thực tế mà Exporter trả về.

## 8. Lưu Dashboard

Sau khi tạo và kiểm tra các Panel:

1. Đặt tên Dashboard: **VM1 Server Monitoring**.
2. Chọn khoảng thời gian: **Last 15 minutes**.
3. Thiết lập Auto refresh: **10s**.
4. Nhấn **Save dashboard**.

Thông tin hiển thị trên Dashboard:

```text
VM1 – SERVER MONITORING
192.168.100.10 · Prometheus · Auto refresh 10s
```

## 9. Kiểm tra hoàn tất

Trước khi kết thúc, kiểm tra các nội dung sau:

- [ ] VM2 chạy Ubuntu Server 24.04 LTS và có IP `192.168.100.20`.
- [ ] Prometheus hoạt động với phiên bản `2.45.3`.
- [ ] Grafana hoạt động với phiên bản `13.2.4`.
- [ ] Grafana truy cập được tại `http://192.168.100.20:3000`.
- [ ] Prometheus truy cập được tại `http://192.168.100.20:9090`.
- [ ] Hai Exporter trên VM1 phản hồi HTTP `200` từ VM2.
- [ ] Các target `vm1-node` và `vm1-process` có trạng thái `UP`.
- [ ] Grafana kết nối thành công với Prometheus.
- [ ] Các truy vấn PromQL trả về dữ liệu.
- [ ] Dashboard `VM1 Server Monitoring` đã được lưu.

**Lưu ý về phạm vi giám sát:** Node Exporter và process-exporter cung cấp số liệu hệ thống và tiến trình. Các chỉ số hiệu năng HTTP như thời gian phản hồi, thông lượng yêu cầu và tỷ lệ lỗi cần được lấy thêm từ công cụ benchmark (k6) chạy trên VM3; không thể chỉ dựa vào Dashboard này để kết luận hiệu năng dịch vụ Web.
