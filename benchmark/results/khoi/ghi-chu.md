# Kết quả benchmark — Khôi (cấu hình gốc, chưa đổi CPU)

Ngày chạy: 2026-11-19 (UTC). Chạy từ VM Test (192.168.100.30) vào `http://192.168.100.10/benchmark/payload.bin`.
Script: `scripts/test/run-benchmark.sh probe`, làm nóng 30 s, đo 120 s, 1 lượt mỗi mức.

## Cấu hình lúc đo

| VM | vCPU | RAM OS nhận | Ghi chú |
| --- | ---: | ---: | --- |
| Server (nginx) | 1 | 1.3 GiB | Nginx 1.24.0, Node Exporter 1.12.1, process-exporter 0.8.7 |
| Monitoring | 2 | 1.8 GiB | Prometheus 2.45.3, Grafana 13.2.4 |
| Test (k6 v2.3.0) | 2 | 1.3 GiB | hostname `kiemThu` |

Payload hợp lệ trước và sau cả hai lượt (HTTP 200, 65.536 byte, SHA-256 khớp).

## Kết quả k6 (cửa sổ 120 s)

| run_id | VU | request | RPS | lỗi | avg ms | p50 ms | p95 ms |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| probe_vu500_lan01 | 500 | 465.614 | 3.880 | 0 | 22,77 | 16,22 | 68,22 |
| probe_vu1000_lan01 | 1000 | 389.930 | 3.249 | 288 (0,074%) | để trống (có status=0) | | |

| probe_vu1000_lan02 | 1000 | 402.680 | 3.356 | 513 (0,127%) | để trống (có status=0) | | |

Lượt 2 chạy lại sau lượt 1 khoảng 40 phút (12:20 UTC). CPU Server avg 90,2% / max 92,8%, Nginx avg 85,5% / max 89,0%; VM Test CPU tổng avg 98% / max 99%, k6 avg 192% / max 197%. Hai lượt 1000 VU cho RPS 3.249 và 3.356 (lệch khoảng 3%), lỗi 0,07% và 0,13%: cùng mức bão hòa, lỗi dao động.

Ở 1000 VU có `status=0` (288 request ở lượt 1, 513 ở lượt 2), nên không điền avg/p50/p95 của cửa sổ (theo quy ước analyzer). Toàn tiến trình k6 cho p95 = 394,81 ms, chỉ để tham khảo, không dùng thay số cửa sổ.

## Tài nguyên trong cửa sổ đo

| Mức | CPU tổng VM Server (avg / max) | CPU Nginx (avg / max) | RAM VM Server | CPU tổng VM Test (avg / max) | CPU tiến trình k6 (avg / max) |
| --- | --- | --- | ---: | --- | --- |
| 500 VU | 65,8% / 69,7% | 62,6% / 66,2% | 28,6% | 82% / 88% | 160% / 175% |
| 1000 VU | 95,8% / 100% | 80,6% / 90,4% | 32,3% / 36,1% max | 93% / 99% | 183% / 196% |

Nguồn: CPU/RAM Server lấy từ Prometheus (truy vấn trong `docs/deployment-guide.md`, bước 5 đến 7; cửa sổ 30 s, bước 5 s). CPU VM Test lấy từ `top -b -d 5` chạy trên VM Test, mẫu mỗi 5 s. Swap VM Test tối đa 1 MiB.

## So sánh với baseline của Khang (`../week2-khang/phan-tich-tong-hop.csv`)

| Mức | RPS Khang | RPS Khôi | p95 Khang | p95 Khôi | Lỗi Khang | Lỗi Khôi |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| 500 VU | 3.031 | 3.880 | 140,2 ms | 68,2 ms | 0 | 0 |
| 1000 VU | 1.969 | 3.249 | không có | không có | 1,47% | 0,07% |

Cấu hình VM giống nhau về vCPU/RAM, nhưng host khác nên số tuyệt đối khác. Không kết luận chênh lệch này do cấu hình, vì chưa đổi yếu tố nào.

## Nhận xét

- Ở 500 VU, Server (1 vCPU) dùng khoảng 66% CPU, chưa kín. Máy phát tải đã dùng 82% CPU tổng và k6 chiếm 160 đến 175% trên 2 vCPU, nên VM Test là nút thắt gần ngang Server.
- Ở 1000 VU, cả Server (khoảng 96 đến 100% CPU) và VM Test (93 đến 99%) gần kín. Lỗi xuất hiện do cả hai đầu quá tải, không quy được riêng cho Server.
- Khi đổi vCPU của Server, nếu RPS không tăng ở 500 và 1000 VU thì cần xét lại giới hạn của VM Test trước khi kết luận.

## Sự cố và ghi chú

- Lượt `official` 30 VU bị dừng giữa chừng khi vừa bắt đầu (khoảng 11:30 đến 11:32 UTC) vì đổi sang đo 500/1000 VU. Dữ liệu lượt đó không được đưa vào bảng; thư mục `20261119T113045Z_official_aBYvTt` vẫn nằm trên VM Test.
- Ba mức thấp (1, 5, 15, 30, 100 VU) chưa chạy lại trên máy này; dùng số của Khang nếu cần so.
- Một lượt mỗi mức, không lặp. Chưa có độ lệch giữa các lượt.
- Script `run-benchmark.sh` được chạy tự động, bước nhập `conditions.md` bị bỏ qua (gửi Enter tự động) và bước xác nhận hồi phục giữa các lượt không có người xem Grafana. Cần điền `conditions.md` thủ công nếu nộp.
- Chưa chụp ảnh Grafana theo từng mức.
- Mẫu thô `samples.ndjson.gz` (56 MB và 48 MB) không đưa vào repo; còn trên VM Test tại `~/ket-qua-benchmark/20261119T113318Z_probe_3bzsE0` và `20261119T113733Z_probe_5Vqbe9`. Log `top` đầy đủ ở `~/top-vmtest.log` trên VM Test.

## Tệp

- `phan-tich-tong-hop.csv`: bảng tổng hợp hai lượt.
- `log/vu500-k6.log`, `log/vu1000-k6.log`: log k6; `*-warmup.log`: log làm nóng.
- `raw-run-info/<run_id>/`: `summary.json`, `check-before/after.txt`, mốc UTC, `conditions-automatic.txt`.
