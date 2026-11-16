# Hướng dẫn chạy benchmark — tuần 2 và tuần 3

Mỗi thành viên tự dựng **đủ 3 VM trên host của mình** theo cấu hình chung. Chạy các lệnh dưới đây trên **VM Test**; Server cung cấp HTTP, Monitoring thu thập metrics. Không cần bấm chạy đồng thời trên ba VM.

## 1. Chuẩn bị

- Cài k6 cùng phiên bản đã dùng (2.3.0), Python 3, curl, gzip và công cụ hệ thống. Xem [hướng dẫn cài k6](INSTALL.md).
- Nginx trả tệp `/benchmark/payload.bin` 65.536 byte; SHA-256 chuẩn `7daca2095d0438260fa849183dfc67faa459fdf4936e1bc91eec6b281b27e4c2`.
- Prometheus có target cần đo ở trạng thái UP; Grafana có dữ liệu CPU, Nginx, RAM, mạng và đĩa. Ghi đúng instance, interface, thiết bị, chu kỳ scrape và cửa sổ truy vấn.
- Kiểm tra `timedatectl` trên từng VM: đồng bộ thời gian thành công. Nếu không phân giải được NTP, kiểm tra kết nối và VMware NAT Service. Các máy có thể dùng IP NTP khác nhau; không coi offset một VM là độ lệch giữa ba VM.
- Giữ cấu hình và tải nền ổn định. Không yêu cầu thu chuỗi thời gian host; ghi rõ ba VM chia sẻ host. Theo dõi CPU/RAM của VM Test khi phát tải.

Sau khi người phụ trách đã chép bộ bàn giao lên main, thành viên lấy mã nguồn:

```bash
git clone https://github.com/Khangvu345/server-monitoring-lab.git
cd server-monitoring-lab
```

Các lệnh tiếp theo chạy tại thư mục gốc repository. Nếu đã clone, lưu thay đổi cá nhân rồi cập nhật main; không ghi đè cấu hình cá nhân.

## 2. Kiểm tra chức năng

```bash
bash scripts/test/run-benchmark.sh smoke 'http://192.168.100.10/benchmark/payload.bin'
```

Script in đường dẫn thư mục kết quả và dừng chờ. Mở terminal khác, điền `conditions.md` trong **đúng thư mục vừa in**; tham khảo `benchmark/conditions.example.md`. Ghi cấu hình, phiên bản, đồng bộ thời gian, cấu hình Nginx và sự cố thực tế. Không sao chép số liệu hiệu năng của thành viên khác. Quay lại nhấn Enter.

Smoke chạy 1 VU trong 15 giây, không làm nóng. Chỉ chuyển tiếp khi HTTP, kích thước, hash trước/sau và kết quả smoke đều đạt. URL phải có `http://`, không kèm dấu ngoặc vuông hoặc cú pháp link Markdown.

## 3. Thăm dò và đo chính thức

```bash
# Chạy thử tải nhẹ: 1, 5, 15 VU; mỗi mức một lượt
bash scripts/test/run-benchmark.sh pilot 'http://192.168.100.10/benchmark/payload.bin'

# Thăm dò một mức khi cần xác nhận môi trường
bash scripts/test/run-benchmark.sh probe 'http://192.168.100.10/benchmark/payload.bin' 500

# Tuần 3: 30, 100, 500 VU; mỗi mức ba lượt, tổng chín lượt
bash scripts/test/run-benchmark.sh official 'http://192.168.100.10/benchmark/payload.bin' 30 100 500
```

**Chỉ chạy official khi đã chốt điều kiện và kiểm tra VM Test ở 500 VU.** Bộ mức 30–100–500 là cấu hình chọn cho lab của Khang, cần đối chiếu trên host của từng thành viên. Nếu VM Test thiếu khả năng phát tải, ghi nhận và thống nhất lại điều kiện/mức tải trước khi so sánh; không âm thầm thay đổi trong cùng đợt.

Luồng tự động: nghỉ ít nhất 60 giây → chờ người chạy xác nhận mức nghỉ → kiểm tra payload → làm nóng 30 giây → đo 120 giây và lưu mẫu → kiểm tra payload → tổng hợp → nghỉ ít nhất 60 giây và chờ xác nhận lượt tiếp. Thời gian nghỉ có thể dài hơn 60 giây nếu chưa hồi phục. Official chạy ba lượt 30 VU, ba lượt 100 VU rồi ba lượt 500 VU.

Không cần chạy lại 1.000 VU để hoàn thành tuần 2. Mức này đã có lỗi và máy phát tải cũng chịu tải cao; chỉ dùng làm minh chứng thăm dò giới hạn. Không dùng để thay thế ba mức baseline.

## 4. Trong và sau mỗi lượt

- Trên VM Test, xem `top` ở terminal thứ hai; ghi CPU tổng, CPU k6, RAM, swap. Ảnh một thời điểm chỉ chứng minh thời điểm đó. Ở 500 VU cần quan sát suốt cửa sổ đo để nhận biết máy phát tải bị giới hạn.
- Chụp Grafana với khoảng thời gian cố định, có phần nghỉ trước/sau, đúng instance; ghi run_id vào tên ảnh. Đổi UTC sang giờ Việt Nam bằng cộng 7 giờ, chú ý qua ngày.
- Xuất dữ liệu giám sát theo `start_utc`–`end_utc` trong `summary.json`, giữ truy vấn, đơn vị và bước thời gian. Ảnh dashboard không thay thế bảng dữ liệu để tính thống kê.
- Khi có lỗi, giữ `k6.log`, log Nginx cùng thời gian và ghi sự cố; không xóa lượt không đẹp. Không kết luận nguyên nhân chỉ từ `status=0`.
- `Ctrl+C` dừng lượt đang chạy; giữ thư mục như minh chứng gián đoạn, không đưa vào bảng các lượt hợp lệ.

Minh chứng cần chụp: đồng bộ NTP/cấu hình; kết quả smoke; bảng tổng hợp cuối lượt; Grafana từng mức; VM Test khi tải cao. Không cần chụp mọi lệnh hoặc mọi giây.

## 5. Đọc kết quả

Mặc định lưu tại `~/ket-qua-benchmark/<UTC>_<mode>_<mã>/`. Có thể đổi bằng `BENCH_RESULT_ROOT=/duong/dan` trước lệnh. Mỗi batch có `conditions.md`, `conditions-automatic.txt`, `summary.csv`; mỗi run có `warmup.log` (trừ smoke), `k6.log`, `samples.ndjson.gz`, `summary.json`, `check-before.txt`, `check-after.txt`, mốc tiến trình và log curl.

Cửa sổ thống kê là `[start_utc, end_utc)`, theo thời điểm mẫu hoàn tất. `request_count` gồm cả request hợp lệ và lỗi trong cửa sổ; RPS = request_count / thời lượng. Mẫu hoàn tất sau cửa sổ được ghi `after_window_count` và loại khỏi thống kê. `k6.log` tổng hợp cả phần hoàn tất trễ nên có thể khác CSV. Warmup chạy riêng, không gộp vào số đo.

Nếu có `status=0`, analyzer hiện để trống avg/p50/p95 và ghi chú; **không điền 0 ms** và không lấy p95 toàn tiến trình k6 thay vào cửa sổ 120 giây. Kiểm tra SHA-256 chỉ diễn ra trước/sau mỗi lượt; từng request k6 kiểm tra HTTP 200 và kích thước, không hash từng phản hồi. Kịch bản giữ nghỉ 100 ms giữa các request của mỗi VU; không thay đổi khi so sánh.

Có thể tính lại từ mẫu gốc, dùng file CSV mới để tránh thêm trùng hàng:

```bash
python3 benchmark/analysis/analyze-results.py /duong/dan/run /tmp/tong-hop-moi.csv probe_vu500_lan01 500 120
```

Lệnh này cập nhật `summary.json` trong run. Sao lưu bản gốc trước khi tính lại.

## 6. Bàn giao

Giữ nguyên thư mục từng batch và thêm ảnh/dữ liệu giám sát, log Nginx, ghi chú sự cố. Ghi `git rev-parse HEAD` cho bộ script; không gán commit mới cho các lượt đã chạy trước khi commit tồn tại. Script tự lưu hash nội dung của ba file lúc chạy.
