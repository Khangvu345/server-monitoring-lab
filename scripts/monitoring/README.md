# Monitoring setup (thủ công)

_Bước 1 — Cài ubuntu server 24.04 và reboot thành công

IP VM2 hiện tại	192.168.100.20

_Bước 2.1 — Kiểm tra phiên bản hệ điều hành
lsb_release -a

Kết quả cần xác nhận Ubuntu 24.04 LTS.

_Bước 2.2 — Kiểm tra địa chỉ IP và card mạng
ip -br addr
ip route

_Bước 2.3 — Kiểm tra kết nối mạng
ping -c 4 8.8.8.8

ping -c 4 google.com

- Nếu cả hai lệnh thành công: kết nối Internet và phân giải DNS cơ bản hoạt động.
- Nếu ping IP thành công nhưng ping tên miền thất bại: cần kiểm tra DNS.
- Nếu cả hai thất bại: kiểm tra cấu hình mạng VMnet NAT trước khi cài phần mềm.

_Bước 2.4 — Cập nhật danh sách gói
sudo apt update


_3. Cài Prometheus trên VM2
Sau khi kiểm tra mạng xong, chạy:
sudo apt install -y prometheus

Kiểm tra version (đồng nhất version 2.45.3):

prometheus --version

Kiểm tra dịch vụ:
sudo systemctl status prometheus --no-pager

Nếu hiển thị active (running) thì dịch vụ đang chạy.

Thiết lập tự khởi động cùng hệ điều hành:
sudo systemctl enable prometheus

Kiểm tra cổng mặc định:
sudo ss -lntp | grep 9090

Kiểm tra Prometheus bằng yêu cầu GET
Chạy lệnh:
curl -s http://localhost:9090/-/ready

Kết quả mong đợi:
Prometheus Server is Ready.

Tiếp theo:
curl -s http://localhost:9090/api/v1/status/buildinfo

Nếu trả về dữ liệu JSON chứa phiên bản Prometheus thì bước cài đặt cơ bản đã ổn.

_4. Cài Grafana trên VM2
Chạy lần lượt từng khối lệnh:

_Bước 4.1 — Cài công cụ cần thiết
sudo apt-get install -y apt-transport-https software-properties-common wget

Đồng nhất các phiên bản: 
- apt-transport-https version 2.8.3
- software-properties-common version 0.99.49.4
- wget version 1.21.4-1ubuntu4.5

_Bước 4.2 — Thêm khóa xác thực và kho Grafana
sudo mkdir -p /etc/apt/keyrings

sudo wget -q -O /etc/apt/keyrings/grafana.asc https://apt.grafana.com/gpg.key

Thêm kho Grafana:
echo "deb [signed-by=/etc/apt/keyrings/grafana.asc] https://apt.grafana.com stable main" | sudo tee /etc/apt/sources.list.d/grafana.list

_Bước 4.3 — Cài Grafana
sudo apt update
sudo apt install -y grafana

Kiểm tra version (đồng nhất version 13.2.4):

grafana --version

_Bước 4.4 — Khởi động và bật tự khởi động
sudo systemctl enable --now grafana-server

Kiểm tra:
sudo systemctl status grafana-server --no-pager

Kiểm tra cổng:
sudo ss -lntp | grep 3000

Grafana mặc định sử dụng cổng 3000. hãy thử mở:
http://192.168.100.20:3000


Lần đăng nhập đầu tiên thường sử dụng:
- Username: admin
- Password: admin
Hệ thống thường yêu cầu đổi mật khẩu sau khi đăng nhập lần đầu. Hãy đặt mật khẩu riêng và không ghi mật khẩu thật vào báo cáo chung.

_5. Kết nối Prometheus với VM1
Đây là bước quan trọng nhất của phần Monitoring: Prometheus phải lấy được dữ liệu thật từ VM1, chứ không chỉ chạy được giao diện.
Mục tiêu: VM2 phải lấy được dữ liệu CPU, RAM, ổ đĩa, mạng và tiến trình từ VM1.


Bước 5.1 – Kiểm tra VM1 đã cài Exporter chưa
Dịch vụ	Phiên bản	Cổng
Node Exporter	1.12.1	9100
process-exporter	0.8.7	9256


Bước 5.2 – Kiểm tra kết nối từ VM2
Trên terminal của VM2, chạy lần lượt:
Kiểm tra Node Exporter:
curl -s -o /dev/null -w "%{http_code}\n" http://192.168.100.10:9100/metrics
Kiểm tra process-exporter:
curl -s -o /dev/null -w "%{http_code}\n" http://192.168.100.10:9256/metrics
Kết quả mong đợi:
200
200
Nếu cả hai đều trả về 200, nghĩa là VM2 đã truy cập được hai nguồn dữ liệu trên VM1.
 
Nếu không được, chưa nên chuyển sang sửa Prometheus. Hãy kiểm tra IP, dịch vụ exporter và firewall trên VM1 trước.


Bước 5.3 – Khai báo VM1 trong Prometheus
Trên VM2, sao lưu file cấu hình:
sudo cp /etc/prometheus/prometheus.yml /etc/prometheus/prometheus.yml.bak
Mở file:
sudo nano /etc/prometheus/prometheus.yml
Tìm phần:
scrape_configs:
Thêm hai job sau vào bên trong danh sách scrape_configs, giữ nguyên job mặc định đang có:
  - job_name: "vm1-node"
    static_configs:
      - targets: ["192.168.100.10:9100"]

  - job_name: "vm1-process"
    static_configs:
      - targets: ["192.168.100.10:9256"]
Lưu ý:
•	Không tạo thêm một scrape_configs: thứ hai.
•	Chú ý thụt lề YAML.
•	Không xóa cấu hình job mặc định.
Lưu bằng Ctrl + O → Enter → Ctrl + X.
 
Kiểm tra cấu hình:
sudo promtool check config /etc/prometheus/prometheus.yml
Nếu hợp lệ, khởi động lại:
sudo systemctl restart prometheus
Kiểm tra:
sudo systemctl status prometheus --no-pager
 

3. Bước 6 – Kết nối Grafana với Prometheus
Sau khi Targets đã UP, chuyển sang Grafana.
Bước 6.1 – Thêm Data Source
Truy cập:
http://192.168.100.20:3000
Đăng nhập Grafana.
Thực hiện:
1.	Chọn Connections.
2.	Chọn Data sources.
3.	Chọn Add data source.
4.	Chọn Prometheus.
5.	Điền URL:
http://localhost:9090
 
6. Nhấn Save & test.
Nếu thành công, Grafana đã kết nối được Prometheus.

 
Bước 6.2 – Kiểm tra dữ liệu
•  Vào Explore.
•  Chọn Data source là Prometheus.
•  Chuyển sang chế độ nhập truy vấn PromQL.
Thử các truy vấn sau:
Chỉ số	PromQL
CPU	rate(node_cpu_seconds_total{mode!="idle"}[5m])
RAM sử dụng (%)	100 * (1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)
Disk	node_filesystem_size_bytes - node_filesystem_avail_bytes
Network nhận	rate(node_network_receive_bytes_total[5m])
Network gửi	rate(node_network_transmit_bytes_total[5m])
 
Đối với process-exporter, thử:
namedprocess_namegroup_num_procs
Nếu các truy vấn trả về dữ liệu, bạn đã có thể bắt đầu tạo dashboard.


6.3. TẠO DASHBOARD MỚI
Truy cập Grafana:
http://192.168.100.20:3000
Thực hiện:
1.	Mở mục Dashboards.
2.	Chọn New → New dashboard.
3.	Nhấn Edit visualization.
4.	Chọn Data source là Prometheus.
 
 
Sau đó tạo 6 panels:
Panel 1 – CPU Usage
Quan trọng
•	Title: VM1 - CPU Usage (%)
•	Visualization: Time series
•	Data source: Prometheus
PromQL:
100 * (1 - avg by (instance) (
  rate(node_cpu_seconds_total{
    instance="192.168.100.10:9100",
    mode="idle"
  }[1m])
))
Truy vấn này tính phần trăm CPU đang sử dụng, không tính thời gian CPU ở trạng thái idle.

Panel 2 – RAM Usage (%)
•	Title: VM1 - RAM Usage (%)
•	Visualization: Time series
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
Trong phần Standard options:
•	Unit: Percent (0-100).
•	Min: 0.
•	Max: 100.


Panel 3 – Disk Usage (%)
•	Title: VM1 - Disk Usage (%)
•	Visualization: Time series
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


Panel 4 – Network Receive
•	Title: VM1 - Network Receive
•	Visualization: Time series
rate(node_network_receive_bytes_total{
  instance="192.168.100.10:9100",
  device="ens33"
}[1m])
Unit: bytes/sec (B/s).


Panel 5 – Network Transmit
•	Title: VM1 - Network Transmit
•	Visualization: Time series
rate(node_network_transmit_bytes_total{
  instance="192.168.100.10:9100",
  device="ens33"
}[1m])
Unit: bytes/sec (B/s).
Lưu ý: Nếu card mạng VM1 không tên ens33, hãy thay bằng tên thực tế lấy từ lệnh ip -br addr trên VM1.


Panel 6 – Process Monitoring
•	Title: VM1 - Process Count
•	Visualization: Time series
namedprocess_namegroup_num_procs{
  instance="192.168.100.10:9256"
}
Panel này giúp theo dõi số lượng tiến trình theo từng nhóm mà process-exporter ghi nhận.


3. Cách lưu từng Panel
Sau khi nhập PromQL:
1.	Nhấn Run queries nếu Grafana chưa tự chạy.
2.	Chọn Visualization → Time series.
3.	Đặt tên tại Panel options → Title.
4.	Chỉnh Unit theo hướng dẫn ở trên.
5.	Nhấn Apply để thêm panel vào Dashboard.
Lặp lại với các truy vấn còn lại.
 
4. Bổ sung hai biểu đồ Disk I/O
Trong đề tài, nhóm cần theo dõi cả hoạt động đọc/ghi ổ đĩa, không chỉ dung lượng đã sử dụng.
Panel 7 – Disk Read
rate(node_disk_read_bytes_total{
  instance="192.168.100.10:9100",
  device="sda"
}[1m])
Panel 8 – Disk Write
rate(node_disk_written_bytes_total{
  instance="192.168.100.10:9100",
  device="sda"
}[1m])
Unit: bytes/sec (B/s).
 
Lưu ý: sda chỉ là ví dụ. Hãy kiểm tra tên ổ đĩa thực tế trên VM1 bằng:
lsblk
Nếu tên ổ đĩa khác thì thay sda bằng tên tương ứng.
 
5. Sắp xếp Dashboard
VM1 – SERVER MONITORING
192.168.100.10 · Prometheus · Auto refresh 15s
Sau khi hoàn thành:
•	Chọn khoảng thời gian Last 15 minutes.
•	Chọn Auto refresh 10s.
•	Nhấn Save dashboard.
•	Đặt tên VM1 Server Monitoring.
 
