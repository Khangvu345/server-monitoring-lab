# Monitoring setup

Đặt script cài đặt Prometheus và Grafana tại đây.

_Bước 1 — Cài ubuntu server 24.04 và reboot thành công

IP VM2 hiện tại	192.168.112.133

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
http://192.168.112.133:3000


Lần đăng nhập đầu tiên thường sử dụng:
- Username: admin
- Password: admin
Hệ thống thường yêu cầu đổi mật khẩu sau khi đăng nhập lần đầu. Hãy đặt mật khẩu riêng và không ghi mật khẩu thật vào báo cáo chung.

(các bước dưới chưa làm)

_5. Kết nối Prometheus với VM1
Đây là bước quan trọng nhất của phần Monitoring: Prometheus phải lấy được dữ liệu thật từ VM1, chứ không chỉ chạy được giao diện.

_Bước 5.1 — Nhờ thành viên phụ trách VM1 cài Node Exporter
Trên VM1, thành viên phụ trách máy chủ cần cài và bật Node Exporter. Nếu dùng gói Ubuntu:
sudo apt update
sudo apt install -y prometheus-node-exporter
sudo systemctl enable --now prometheus-node-exporter

Kiểm tra dịch vụ:
sudo systemctl status prometheus-node-exporter --no-pager

Node Exporter mặc định cung cấp metrics ở cổng 9100.

_Bước 5.2 — Kiểm tra từ VM2
Trên VM2, thay địa chỉ IP bên dưới bằng IP thật của VM1:
curl http://192.168.100.10:9100/metrics

Nếu thành công, bạn sẽ thấy nhiều dòng dữ liệu, chẳng hạn các chỉ số bắt đầu bằng node_cpu, node_memory, node_disk và node_network.

Nếu gặp lỗi kết nối, kiểm tra IP, mạng VMnet NAT và firewall trên VM1 trước. Không nên vội sửa cấu hình Prometheus khi VM2 chưa truy cập được endpoint này.

_Bước 5.3 — Khai báo VM1 trong Prometheus
Trên VM2, sao lưu cấu hình trước khi chỉnh sửa:
sudo cp /etc/prometheus/prometheus.yml \
  /etc/prometheus/prometheus.yml.bak

Mở file:
sudo nano /etc/prometheus/prometheus.yml

Tìm phần scrape_configs: hiện có. Bên trong danh sách này, thêm một job mới, giữ nguyên job mặc định đang có:
  - job_name: "vm1-node"
    static_configs:
      - targets: ["192.168.100.10:9100"]

Lưu ý:
- Dấu cách trong YAML phải chính xác.
- Không tạo một mục scrape_configs: thứ hai.
- Đổi 192.168.100.10 thành IP thực tế của VM1.
Lưu file trong Nano bằng Ctrl + O, nhấn Enter, rồi thoát bằng Ctrl + X.

Kiểm tra cấu hình:
sudo promtool check config /etc/prometheus/prometheus.yml

Nếu hợp lệ, khởi động lại Prometheus:
sudo systemctl restart prometheus

Mở http://IP_CUA_VM2:9090/targets và kiểm tra job vm1-node.

Kết quả cần đạt:
vm1-node — UP

Prometheus truy cập được Node Exporter và thu thập metrics thành công.

vm1-node — DOWN

Kiểm tra lại endpoint bằng curl, địa chỉ IP, cổng 9100, firewall và cấu hình target.

_6. Kết nối Grafana với Prometheus và tạo dashboard
Khi vm1-node đã ở trạng thái UP, bạn mới chuyển sang bước này.

_Bước 6.1 — Thêm nguồn dữ liệu Prometheus
1. Mở http://IP_CUA_VM2:3000.
2. Đăng nhập Grafana.
3. Vào Connections → Data sources → Add data source.
4. Chọn Prometheus.
5. Nhập URL:
http://localhost:9090

Vì Prometheus và Grafana đều chạy trên VM2, dùng localhost là phù hợp với cấu hình hiện tại.

6. Nhấn Save & test. Xác nhận kết nối thành công.

_Bước 6.2 — Kiểm tra thử các chỉ số
Trong Grafana, mở khu vực Explore, chọn nguồn dữ liệu Prometheus và chạy từng truy vấn:
Chỉ số	PromQL mẫu
CPU sử dụng theo từng CPU	rate(node_cpu_seconds_total{mode!="idle"}[5m])
RAM đã sử dụng (%)	100 * (1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)
Dung lượng ổ đĩa đã sử dụng	node_filesystem_size_bytes - node_filesystem_avail_bytes
Lưu lượng nhận mạng	rate(node_network_receive_bytes_total[5m])
Lưu lượng gửi mạng	rate(node_network_transmit_bytes_total[5m])

Các truy vấn trên là ví dụ ban đầu. Khi tạo dashboard chính thức, cần lọc đúng thiết bị mạng, filesystem và loại trừ các thiết bị ảo không cần thiết.

Để tiết kiệm thời gian, bạn có thể import dashboard Node Exporter có sẵn, sau đó kiểm tra các biểu đồ có đúng dữ liệu của VM1 không. Đừng chỉ chụp dashboard mẫu khi dữ liệu vẫn trống.

Lưu ý về yêu cầu nhóm: Node Exporter chủ yếu cung cấp metrics hệ thống. Thông lượng HTTP, thời gian đáp ứng và tỷ lệ lỗi phải lấy thêm từ công cụ benchmark như k6 trên VM3; không thể chỉ dựa vào dashboard CPU/RAM để kết luận hiệu năng dịch vụ Web.
