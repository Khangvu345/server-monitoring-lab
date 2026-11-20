# Official, `access_log off` — 30 / 100 / 500 VU × 3 lượt

Ngày chạy: 2026-11-20, 00:14 đến 00:48 UTC. Cùng quy trình với `../official-truoc-toi-uu/`.

## Thay đổi so với cấu hình gốc

Chỉ một thay đổi trên Server: `/etc/nginx/nginx.conf`, dòng `access_log /var/log/nginx/access.log;` thành `access_log off;` (nginx -t đạt, reload; bản gốc sao lưu `/etc/nginx/nginx.conf.bak-goc`). Server 1 vCPU, Test 4 vCPU không đổi. Xác nhận không ghi log nữa: ghi đĩa trong lúc đo chỉ 0,2 đến 2,5 KiB/s (so với 35 đến 433 KiB/s khi bật log).

## Kết quả từng lượt (k6, cửa sổ 120 s)

| Mức | Lần | RPS | avg ms | p50 ms | p95 ms | Lỗi % | CPU Server % (avg / max) | Ghi đĩa KiB/s | Mạng ra MiB/s |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | --- | ---: | ---: |
| 30 VU | 1 | 294,00 | 1,549 | 1,312 | 3,295 | 0 | 7,83 / 8,04 | 2,48 | 19,24 |
| 30 VU | 2 | 293,78 | 1,538 | 1,158 | 3,942 | 0 | 9,76 / 14,40 | 1,25 | 18,97 |
| 30 VU | 3 | 294,01 | 1,531 | 1,239 | 3,198 | 0 | 8,34 / 10,64 | 0,23 | 19,23 |
| 100 VU | 1 | 981,43 | 1,435 | 1,124 | 2,885 | 0 | 21,21 / 21,72 | 2,05 | 64,22 |
| 100 VU | 2 | 980,33 | 1,481 | 1,134 | 3,356 | 0 | 21,30 / 22,44 | 0,93 | 64,15 |
| 100 VU | 3 | 981,56 | 1,408 | 1,124 | 2,991 | 0 | 20,58 / 21,20 | 0,20 | 64,18 |
| 500 VU | 1 | 4.745,36 | 3,964 | 1,770 | 14,111 | 0 | 73,60 / 76,88 | 0,25 | 310,42 |
| 500 VU | 2 | 4.777,73 | 3,446 | 1,671 | 11,548 | 0 | 73,16 / 74,12 | 0,87 | 313,03 |
| 500 VU | 3 | 4.764,28 | 3,636 | 1,745 | 12,626 | 0 | 72,93 / 74,44 | 1,79 | 312,94 |

Số liệu Server đầy đủ (RAM, IOPS, retransmit...) ở `so-lieu-server-prometheus.csv`.

## So với bộ "trước" (access_log bật, phiên 2026-11-19 16:50 UTC)

| Mức | RPS trước → sau | p95 ms trước → sau | CPU Server trước → sau |
| --- | --- | --- | --- |
| 30 VU | 293,76 → 293,93 (+0,06%) | 3,32 → 3,48 | 8,29 → 8,64 |
| 100 VU | 979,27 → 981,11 (+0,19%) | 3,07 → 3,08 | 27,46 → 21,03 |
| 500 VU | 3.717,4 → 4.762,5 (+28,1%) | 64,3 → 12,8 | 98,9 → 73,2 |

## Kết luận tạm: có dấu hiệu cải thiện, nhưng chưa tách được ảnh hưởng của môi trường

- Ở 30 và 100 VU không có khác biệt đáng kể (Server còn dư nhiều CPU, không phải nút thắt).
- Ở 500 VU RPS tăng 28%, p95 giảm khoảng 5 lần, CPU Server giảm từ 99% xuống 73%.
- **Hạn chế quan trọng:** bộ "trước" và bộ này chạy ở hai phiên cách nhau nhiều giờ (VM khởi động lại giữa hai phiên). Trước đó, với `access_log` **bật**, một lượt 500 VU buổi chiều 2026-11-19 (`../buoc1-test4core/`) đã cho 4.722 RPS, p95 15,7 ms, CPU 78%, gần giống kết quả hôm nay. Nghĩa là phiên chạy hôm qua 16:50 có thể là phiên "chậm", làm phóng đại hiệu quả của `access_log off`. Để kết luận, cần đo lại `access_log` bật ngay trong phiên này (cùng ngày, liền kề).
- Chưa điền `conditions.md`, chưa chụp Grafana. Mẫu thô còn trên VM Test: `~/ket-qua-benchmark/20261120T001233Z_official_KHCw29`.
