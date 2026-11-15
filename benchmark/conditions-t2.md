# Điều kiện thực nghiệm — tuần 2

## Người thực hiện và máy host

- Người thực hiện: Khang.
- Máy host: CPU 12 nhân 16 luồng; RAM 16 GB; ổ cứng NVMe, hệ điều hành Windows.
- Nền tảng ảo hoá: VMware Workstation Pro 25H2.
- Ba VM dùng chung một host và mạng VMware NAT; sự cạnh tranh tài nguyên host có thể ảnh hưởng kết quả.

## Đồng bộ thời gian

- Múi giờ của VM Test khi kiểm tra: Asia/Ho_Chi_Minh (UTC+07:00); các mốc của k6 trong kết quả ghi theo UTC.
- Theo kiểm tra, hai VM còn lại dùng cùng một địa chỉ máy chủ NTP; VM Test dùng địa chỉ khác, vì vậy thời gian giữa các máy có thể chênh lệch nhỏ. Kiểm tra lại trạng thái đồng bộ trên từng VM trước đợt đo.

## Cấu hình ba VM

Các trị số dưới đây đo trực tiếp từ các máy ảo.

| Vai trò | Hostname | IP | vCPU | RAM hệ điều hành nhận | Đĩa | Hệ điều hành |
| --- | --- | --- | ---: | ---: | ---: | --- |
| Cung cấp dịch vụ | server | 192.168.100.10 | 1 | 1.3 GiB | 10G | Ubuntu 24.04.5 LTS |
| Giám sát | monitoring | 192.168.100.20 | 2 | 1.9 GiB | 10G | Ubuntu 24.04.5 LTS |
| Phát tải | test | 192.168.100.30 | 2 | 1.4 GiB | 10G | Ubuntu 24.04.5 LTS |

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

- Endpoint từ VM Test: `http://192.168.100.10/benchmark/payload.bin`.
- Tác vụ: một VU gửi GET, chờ phản hồi, nghỉ 100 ms rồi lặp; giữ kết nối và cấu hình tải nhất quán khi so sánh.
- Tệp tĩnh: 65.536 byte (64 KiB); dãy byte 0–255 lặp 256 lần theo script thiết lập.
- SHA-256 chuẩn trong script của Khôi: `7daca2095d0438260fa849183dfc67faa459fdf4936e1bc91eec6b281b27e4c2`
- Kịch bản gửi `Accept-Encoding: identity`, không theo redirect, timeout 10 giây/request; phản hồi hợp lệ là HTTP 200 và đủ 65.536 byte.
- Site benchmark theo cấu hình trong repository: `/etc/nginx/sites-enabled/benchmark`, cổng 80, tệp trong `/var/www/benchmark`, `gzip off`. 
- Cách cấu hình log, cache, keep-alive và các tùy chỉnh Nginx khác trên máy thực tế: chưa xác nhận; ghi lại và giữ nguyên giữa các lượt so sánh.

## Đối tượng giám sát

- `lsblk` cho thấy đĩa của VM Server là `sda` và `/` là logical volume; cần xác nhận thiết bị nào phù hợp để truy vấn I/O của đường dẫn payload. Tên card mạng phục vụ HTTP: ens33.
- Tình trạng CPU, RAM, mạng, ổ đĩa của ba VM và tải nền của host tại thời điểm trước mỗi lượt: chưa đo; theo dõi thực tế trên Grafana/host và ghi nếu bất thường.

## Quy trình chạy và tình trạng

- Smoke: 1 VU, 15 giây; 
- Pilot: 1, 5 và 15 VU, mỗi mức một lượt; mỗi lượt làm nóng 30 giây bằng tiến trình riêng, đo 120 giây, nghỉ ít nhất 60 giây và chờ tài nguyên ổn định.
- Mỗi lượt lưu mẫu k6, `summary.csv`, mốc UTC, kết quả kiểm tra hash trước/sau; thu thêm dữ liệu Prometheus/Grafana cho cùng khoảng thời gian.
- Ba mức tải thấp/trung bình/cao chính thức - 30VU/100VU/500VU.
- Yếu tố tối ưu và cấu hình trước/sau: chưa chọn; ghi khi lập phép đo tuần 3.
- Sự cố, mất mẫu, lượt bị gián đoạn hoặc phải chạy lại: chưa phát sinh kết quả đo trong bản ghi này; bổ sung khi thực hiện.

File `conditions-automatic.txt` do script tạo chỉ tự ghi những thông tin nhìn thấy từ VM Test. Không dùng thông số dự kiến hoặc ảnh kiểm tra cấu hình làm số liệu hiệu năng thực nghiệm.
