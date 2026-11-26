# Official, cấu hình gốc ("trước tối ưu") — 30 / 100 / 500 VU × 3 lượt

Ngày chạy: 2026-11-19, 16:50 đến 17:24 UTC. Lệnh: `run-benchmark.sh official ... 30 100 500` (làm nóng 30 s, đo 120 s, nghỉ 60 s).

## Cấu hình lúc đo

| VM | vCPU | Ghi chú |
| --- | ---: | --- |
| Server | 1 | Nginx 1.24.0 mặc định Ubuntu: `worker_connections 768`, `access_log` bật, chưa chỉnh gì. TSO/GSO bật |
| Monitoring | 2 | Prometheus 2.45.3, Grafana 13.2.4 |
| Test | 4 | 2 sockets × 2 cores; k6 v2.3.0 |

Payload hợp lệ trước và sau cả 9 lượt (hash khớp). Không có request lỗi ở lượt nào.

## Kết quả từng lượt (k6, cửa sổ 120 s)

| Mức | Lần | Request | RPS | avg ms | p50 ms | p95 ms | Lỗi % |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 30 VU | 1 | 35.251 | 293,76 | 1,631 | 1,431 | 3,104 | 0 |
| 30 VU | 2 | 35.250 | 293,75 | 1,631 | 1,389 | 3,505 | 0 |
| 30 VU | 3 | 35.254 | 293,78 | 1,617 | 1,366 | 3,354 | 0 |
| 100 VU | 1 | 117.531 | 979,43 | 1,595 | 1,215 | 3,583 | 0 |
| 100 VU | 2 | 117.502 | 979,18 | 1,534 | 1,319 | 2,827 | 0 |
| 100 VU | 3 | 117.503 | 979,19 | 1,536 | 1,321 | 2,790 | 0 |
| 500 VU | 1 | 447.073 | 3.725,61 | 30,05 | 26,09 | 62,51 | 0 |
| 500 VU | 2 | 444.547 | 3.704,56 | 30,83 | 25,99 | 67,32 | 0 |
| 500 VU | 3 | 446.629 | 3.721,91 | 30,31 | 26,31 | 62,97 | 0 |

## Tài nguyên Server từng lượt (Prometheus, cửa sổ 120 s)

Số liệu đầy đủ ở `so-lieu-server-prometheus.csv`.

| Mức | Lần | CPU % (avg / max) | RAM % | Ghi đĩa KiB/s | Mạng ra MiB/s | TCP retransmit /s |
| --- | ---: | --- | ---: | ---: | ---: | ---: |
| 30 VU | 1 | 7,91 / 8,56 | 27,34 | 36,8 | 19,23 | 0,91 |
| 30 VU | 2 | 8,43 / 8,91 | 27,01 | 37,3 | 19,23 | 0,91 |
| 30 VU | 3 | 8,52 / 8,92 | 27,69 | 34,2 | 19,22 | 0,93 |
| 100 VU | 1 | 22,37 / 23,79 | 27,53 | 116,8 | 64,05 | 11,8 |
| 100 VU | 2 | 29,80 / 30,28 | 27,34 | 112,1 | 63,99 | 2,3 |
| 100 VU | 3 | 30,22 / 32,16 | 27,57 | 119,8 | 64,01 | 0,71 |
| 500 VU | 1 | 98,95 / 99,68 | 28,14 | 413,2 | 245,65 | 381,2 |
| 500 VU | 2 | 98,77 / 99,84 | 28,24 | 432,9 | 243,30 | 365,8 |
| 500 VU | 3 | 98,94 / 99,72 | 28,34 | 433,3 | 244,78 | 390,6 |

Ổ đĩa gần như không đọc (0 KiB/s; payload nằm trong page cache), chỉ ghi nhật ký khoảng 35 đến 430 KiB/s, tăng theo tải; IOPS khoảng 1/s. CPU VM Test của lượt này chưa trích xuất; log `top` còn ở `~/top-vmtest-base-official.log` trên VM Test.

## Trung bình 3 lượt (dùng cho bảng 7.4)

| Mức | RPS | avg ms | p95 ms | CPU Server % |
| --- | ---: | ---: | ---: | ---: |
| 30 VU | 293,76 | 1,627 | 3,321 | 8,29 |
| 100 VU | 979,27 | 1,555 | 3,067 | 27,46 |
| 500 VU | 3.717,36 | 30,40 | 64,27 | 98,89 |

## Lưu ý quan trọng

- Ở 500 VU Server (1 vCPU) **kín CPU** (khoảng 99%), nên đây là mức Server là nút thắt: phù hợp để thấy tác dụng của tối ưu.
- Cùng cấu hình (Server 1 vCPU, Test 4 vCPU), lượt đơn trước đó (Bước 1, buổi chiều) cho 500 VU: **4.722 RPS, p95 15,7 ms, CPU Server 78%**; lần này chỉ 3.717 RPS, p95 64 ms, CPU 99%. Cùng một cấu hình cho kết quả khác nhau giữa hai buổi chạy (cách nhau vài giờ, có khởi động lại VM và đổi cấu hình ở giữa). Chưa rõ nguyên nhân (có thể trạng thái host hoặc VM). Hệ quả: **"trước" và "sau" phải đo liền kề trong cùng một phiên**, không so với số của phiên khác.
- Ba lượt trong cùng phiên rất đồng đều (RPS lệch dưới 1%), nên phiên này tự nhất quán.
- Chưa điền `conditions.md`, chưa chụp Grafana.
- Mẫu thô còn trên VM Test: `~/ket-qua-benchmark/20261119T164839Z_official_mvOPxr`.
