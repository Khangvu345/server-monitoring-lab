# Điều kiện thực nghiệm — Benchmark official

## 1. Người thực hiện và máy host

- Người thực hiện: Nhóm thực hiện đề tài giám sát máy chủ bằng Prometheus và Grafana.
- Máy host: Máy tính cá nhân chạy Windows 10 22H2.
- Nền tảng ảo hóa: VMware Workstation 25.0.1.1473.
- Mạng ảo: VMware NAT, mạng `192.168.100.0/24`.
- Ba máy ảo được triển khai trên cùng một máy host.
- Tài nguyên CPU, RAM và I/O của máy host được chia sẻ giữa các máy ảo. Tải nền của host có thể ảnh hưởng đến kết quả benchmark.

## 2. Đồng bộ thời gian

- Múi giờ sử dụng: `Asia/Ho_Chi_Minh`.
- Cả ba VM đã được kiểm tra trạng thái đồng bộ thời gian và NTP đang hoạt động.

Thông tin kiểm tra gần nhất trước lần benchmark mới:

| VM | NTP hoạt động | Đồng bộ thời gian | Máy chủ NTP | Stratum | Offset |
|---|---|---|---|---:|---:|
| VM1 - Server | Có | Có | 185.125.190.56 | 2 | +354.703 ms |
| VM2 - Monitoring | Có | Có | 185.125.190.56 | 2 | -0.619 ms |
| VM3 - Test | Có | Có | 185.125.190.58 | 2 | -43.875 ms |

Lưu ý: Các giá trị offset là kết quả kiểm tra trước đó, không phải số đo được xác nhận lại tại thời điểm bắt đầu lần benchmark này.

## 3. Cấu hình ba máy ảo

### 3.1. Cấu hình VMware

| Vai trò | Hostname | IP | vCPU | RAM cấp phát | Ổ đĩa ảo | Hệ điều hành |
|---|---|---|---:|---:|---:|---|
| Cung cấp dịch vụ | server | 192.168.100.10 | 1 | 1.5 GB | 20 GB | Ubuntu 24.04.5 LTS |
| Giám sát | monitoring | 192.168.100.20 | 2 | 2 GB | 30 GB | Ubuntu 24.04.5 LTS |
| Phát tải | test | 192.168.100.30 | 2 | 1.5 GB | 20 GB | Ubuntu 24.04.5 LTS |

### 3.2. Kết quả kiểm tra từ hệ điều hành

| VM | CPU logic | RAM hệ điều hành nhận | Đĩa `/dev/sda` | Logical volume `/` |
|---|---:|---:|---:|---:|
| VM1 - Server | 1 | 1.4 GiB | 20 GB | 10 GB |
| VM2 - Monitoring | 2 | 1.9 GiB | 30 GB | 14 GB |
| VM3 - Test | 2 | 1.4 GiB | 20 GB | 10 GB |

Lưu ý:
- `nproc` xác nhận số CPU logic mà hệ điều hành nhận diện.
- RAM hệ điều hành nhận diện có thể thấp hơn RAM cấp phát trong VMware.
- Dung lượng ổ đĩa ảo không đồng nhất với dung lượng logical volume gắn tại `/`.
- RAM sử dụng, RAM trống và RAM khả dụng thay đổi theo thời điểm kiểm tra.

## 4. Phiên bản phần mềm

Các phiên bản đã được kiểm tra trong quá trình thiết lập hệ thống:

| VM | Thành phần | Phiên bản |
|---|---|---|
| Server | Ubuntu Server | 24.04.5 LTS |
| Server | Nginx | 1.24.0 |
| Server | Node Exporter | 1.12.1 |
| Server | process-exporter | 0.8.7 |
| Monitoring | Ubuntu Server | 24.04.5 LTS |
| Monitoring | Prometheus | 2.45.3 |
| Monitoring | Grafana | 13.2.4 |
| Test | Ubuntu Server | 24.04.5 LTS |
| Test | k6 | v2.3.0 |
| Test | Python | 3.12.3 |

## 5. Cấu hình dịch vụ và dữ liệu

- Máy chủ VM1 cung cấp nội dung thông qua Nginx.
- Giao thức HTTP, cổng 80.
- Địa chỉ payload: `http://192.168.100.10/benchmark/payload.bin`.
- Kích thước payload: 65.536 byte (64 KiB).
- SHA-256 kỳ vọng:

`7daca2095d0438260fa849183dfc67faa459fdf4936e1bc91eec6b281b27e4c2`

- File manifest: `/etc/benchmark/manifest.txt`.
- Kịch bản phát tải: `benchmark/k6/http-test.js`.
- Script điều khiển benchmark: `scripts/test/run-benchmark.sh`.

Trước và sau mỗi lượt benchmark, script kiểm tra:
- HTTP status phải là 200.
- Kích thước payload phải đúng 65.536 byte.
- SHA-256 phải trùng khớp giá trị kỳ vọng.

## 6. Đối tượng và hệ thống giám sát

VM2 sử dụng Prometheus để thu thập dữ liệu và Grafana để trực quan hóa tình trạng VM1.

| Thành phần | Máy triển khai | Cổng |
|---|---|---:|
| Nginx | VM1 | 80 |
| Node Exporter | VM1 | 9100 |
| process-exporter | VM1 | 9256 |
| Prometheus | VM2 | 9090 |
| Grafana | VM2 | 3000 |

Các nhóm chỉ số giám sát:
- CPU Usage: mức sử dụng CPU.
- Memory Usage: dung lượng RAM sử dụng và khả dụng.
- Network Receive/Transmit: lưu lượng mạng nhận và truyền.
- Disk Read/Write: hoạt động đọc và ghi ổ đĩa.
- Nginx CPU/RAM: tài nguyên CPU và RAM của tiến trình Nginx.
- Process Count: số lượng tiến trình được giám sát.

Cấu hình thu thập:
- Prometheus scrape interval: 15 giây.
- Prometheus evaluation interval: 15 giây.
- Grafana dashboard refresh: 10 giây.
- Dashboard: `VM1 Server Monitoring`.
- process-exporter theo dõi nhóm tiến trình `nginx`.

## 7. Quy trình benchmark official

- Chế độ: official.
- Công cụ phát tải: k6 v2.3.0.
- Mục tiêu: đánh giá khả năng phục vụ HTTP của VM1 khi số lượng người dùng ảo tăng dần.

Các mức tải:

| Mức tải | Virtual Users (VU) | Số lần lặp |
|---|---:|---:|
| Thấp | 30 | 3 |
| Trung bình | 100 | 3 |
| Cao | 500 | 3 |
| Tổng cộng | 3 mức | 9 lượt |

Thông số mỗi lượt:
- Warm-up: 30 giây.
- Thời gian đo chính thức: 120 giây.
- Thời gian nghỉ giữa các lượt: tối thiểu 60 giây.
- Kiểm tra trạng thái hệ thống trước khi tiếp tục lượt kế tiếp.

Quy trình:
1. Kiểm tra tình trạng hoạt động của ba VM.
2. Kiểm tra dịch vụ Nginx và payload.
3. Kiểm tra dashboard Grafana và các chỉ số nền.
4. Thực hiện warm-up theo mức VU.
5. Thực hiện đo chính thức trong 120 giây.
6. Lưu dữ liệu k6 của từng lượt.
7. Kiểm tra lại payload sau mỗi lượt.
8. Nghỉ tối thiểu 60 giây và kiểm tra hệ thống trước lượt tiếp theo.
9. Tổng hợp kết quả vào `summary.csv`.

## 8. Lưu trữ kết quả

Thư mục kết quả của lần benchmark này:

`20261119T144504Z_official_92SKtV`

Các dữ liệu dự kiến được lưu:
- `conditions.md`: điều kiện thực nghiệm.
- `conditions-automatic.txt`: thông tin tự động thu thập từ VM Test.
- Các thư mục kết quả riêng cho từng mức VU và lần lặp.
- `summary.csv`: bảng tổng hợp kết quả benchmark.

## 9. Giới hạn và lưu ý

- Ba VM sử dụng chung tài nguyên máy host, do đó tài nguyên host có thể ảnh hưởng đến kết quả.
- Số liệu RAM và CPU có thể biến động trong quá trình thực nghiệm.
- Chu kỳ scrape Prometheus 15 giây không đồng nghĩa với việc mọi biến động ngắn hơn 15 giây đều được ghi nhận đầy đủ.
- Dữ liệu Disk I/O cần được diễn giải thận trọng vì dữ liệu có thể được phục vụ từ page cache.
- Không đồng nhất số request hoàn thành sau cửa sổ đo với số request lỗi.
- Kết quả benchmark cần được phân tích đồng thời với latency, throughput, tỷ lệ lỗi và dữ liệu giám sát hệ thống.
