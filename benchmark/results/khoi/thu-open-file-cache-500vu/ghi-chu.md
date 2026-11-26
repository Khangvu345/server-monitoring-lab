# Thử `open_file_cache` — 500 VU × 3 lượt

Ngày chạy: 2026-11-20, 02:11 đến 02:24 UTC, cùng phiên với `../kiem-soat-access-log-on-500vu/` (01:42 đến 01:55 UTC).

## Thay đổi so với cấu hình gốc

Thêm vào khối `http` của `/etc/nginx/nginx.conf` (sau `gzip on;`), `access_log` vẫn bật:

```
open_file_cache max=100 inactive=60s;
open_file_cache_valid 60s;
open_file_cache_min_uses 1;
open_file_cache_errors on;
```

`nginx -t` đạt, reload thành công, xác nhận bằng `nginx -T`. Server 1 vCPU, Test 4 vCPU. Bản gốc ở `/etc/nginx/nginx.conf.bak-goc` (đã khôi phục sau thử nghiệm).

## Kết quả

| Cấu hình (500 VU) | Lần | RPS | avg ms | p50 ms | p95 ms | Lỗi | CPU Server % (avg / max) | CPU Nginx % | Retransmit /s |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | --- | ---: | ---: |
| open_file_cache | 1 | 4.660,33 | 5,589 | 2,150 | 19,365 | 0 | 75,98 / 80,12 | 73,13 | 657,1 |
| open_file_cache | 2 | 4.711,33 | 4,660 | 1,894 | 16,225 | 0 | 74,98 / 78,76 | 72,22 | 520,5 |
| open_file_cache | 3 | 4.684,13 | 5,050 | 2,087 | 18,201 | 0 | 75,39 / 78,08 | 72,55 | 556,3 |

## So sánh trong cùng phiên (500 VU, trung bình 3 lượt)

| Cấu hình | RPS | avg ms | p95 ms | CPU Server % |
| --- | ---: | ---: | ---: | ---: |
| Gốc (access_log bật, không cache) | 4.684,1 | 5,16 | 18,24 | 77,7 |
| access_log tắt | 4.762,5 | 3,68 | 12,76 | 73,2 |
| **open_file_cache** | **4.685,3** | 5,10 | 17,93 | 75,5 |

## Kết luận

`open_file_cache` **không cải thiện** thông lượng: RPS 4.685 so với 4.684 của cấu hình gốc (chênh 0,03%), p95 giảm khoảng 2% và CPU Server giảm khoảng 2 điểm, đều nằm trong dao động giữa các lượt. Lý do hợp lý: payload chỉ là một tệp 64 KiB nằm sẵn trong page cache của hệ điều hành, nên bước mở/kiểm tra tệp của Nginx vốn đã rẻ. Đây là suy luận, chưa đo trực tiếp.

Lưu ý: chỉ đo ở 500 VU, mỗi cấu hình 3 lượt; chưa đo ở 1000 VU.
