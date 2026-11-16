# Điều kiện thực nghiệm — tuần 2

## Người thực hiện và máy host

- Người thực hiện: 
- Máy host: 
- Nền tảng ảo hoá: 
- Ba VM dùng chung một host và mạng VMware NAT; sự cạnh tranh tài nguyên host có thể ảnh hưởng kết quả.

## Đồng bộ thời gian

- Kiểm tra máy chủ thời gian của 3 server ghi note vào đây

## Cấu hình ba VM

Các trị số dưới đây đo trực tiếp từ các máy ảo.

| Vai trò | Hostname | IP | vCPU | RAM hệ điều hành nhận | Đĩa | Hệ điều hành |
| --- | --- | --- | ---: | ---: | ---: | --- |
| Cung cấp dịch vụ | server | 192.168.100.10 | 1 | - | 10G | Ubuntu 24.04.5 LTS |
| Giám sát | monitoring | 192.168.100.20 | 2 | - | 10G | Ubuntu 24.04.5 LTS |
| Phát tải | test | 192.168.100.30 | 2 | - | 10G | Ubuntu 24.04.5 LTS |

- Ảnh kiểm tra cho thấy ổ `sda` 10G ở cả ba VM; phân vùng logic gắn tại `/` có kích thước 8.2G. Không nhầm kích thước phân vùng với dung lượng còn trống.
- Kiểu socket/core ghi trong báo cáo: Server 1 processor × 1 core, Monitoring và Test mỗi máy 1 processor × 2 core. Ảnh `nproc` chỉ xác nhận số vCPU, chưa kiểm chứng topology ở thời điểm này.

## Phiên bản công cụ

Các phiên bản sau lấy từ kết quả lệnh người thực hiện cung cấp:

| VM | Thành phần | Phiên bản thực tế được báo |
| --- | --- | --- |
| Server | Nginx | 1.24.0  |
| Server | Node Exporter | 1.12.1 |
| Server | process-exporter | 0.8.7 |
| Monitoring | Prometheus | 2.45.3 |
| Monitoring | Grafana | 13.2.4 |
| Test | k6 | v2.3.0 |
| Test | Python | 3.12.3 |

Ghi chú: báo cáo chung trước đây có chỗ ghi Node Exporter 1.7.0; kết quả vừa kiểm tra trên VM Server là 1.12.1. Cần cập nhật báo cáo theo kết quả thực tế.

## Cấu hình dịch vụ và dữ liệu

- Kịch bản điền lại nếu có thay đổi

## Đối tượng giám sát

- `lsblk` cho thấy đĩa của VM Server là `sda` và `/` là logical volume; cần xác nhận thiết bị nào phù hợp để truy vấn I/O của đường dẫn payload. Tên card mạng phục vụ HTTP: ens33.
- Tình trạng CPU, RAM, mạng, ổ đĩa của ba VM và tải nền của host tại thời điểm trước mỗi lượt: chưa đo; theo dõi thực tế trên Grafana/host và ghi nếu bất thường.

## Quy trình chạy và tình trạng

- Điền lại kịch bản nếu có thay đổi

File `conditions-automatic.txt` do script tạo chỉ tự ghi những thông tin nhìn thấy từ VM Test. Không dùng thông số dự kiến hoặc ảnh kiểm tra cấu hình làm số liệu hiệu năng thực nghiệm.
