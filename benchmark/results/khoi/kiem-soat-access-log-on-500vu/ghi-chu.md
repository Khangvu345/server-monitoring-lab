# Kiểm soát: `access_log` bật lại, 500 VU × 3 lượt (cùng phiên với `access_log off`)

Ngày chạy: 2026-11-20, 01:42 đến 01:55 UTC, ngay sau bộ `../official-access-log-off/` (00:14 đến 00:48 UTC). Mục đích: tách ảnh hưởng của `access_log` khỏi dao động môi trường giữa các phiên.

Cấu hình: Server 1 vCPU, Test 4 vCPU. `nginx.conf` được khôi phục từ bản sao lưu (`diff` giống bản gốc, `access_log` bật và ghi log: 2 lên 3 dòng sau một request thử). Chạy bằng `probe` 500 VU ba lần liên tiếp (làm nóng 30 s, đo 120 s, nghỉ 60 s).

## Kết quả

| Cấu hình | Lần | RPS | avg ms | p50 ms | p95 ms | Lỗi | CPU Server % (avg / max) | Ghi đĩa KiB/s | Mạng ra MiB/s | Retransmit /s |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | --- | ---: | ---: | ---: |
| access_log **bật** | 1 | 4.622,30 | 6,244 | 2,572 | 22,082 | 0 | 78,84 / 81,92 | 525,6 | 302,1 | 533,9 |
| access_log **bật** | 2 | 4.682,31 | 5,253 | 2,225 | 18,242 | 0 | 77,82 / 80,92 | 540,3 | 307,5 | 515,9 |
| access_log **bật** | 3 | 4.747,73 | 3,978 | 1,889 | 14,396 | 0 | 76,49 / 78,20 | 526,0 | 310,8 | 246,8 |
| access_log tắt | 1 | 4.745,36 | 3,964 | 1,770 | 14,111 | 0 | 73,60 / 76,88 | 0,25 | 310,4 | 311,2 |
| access_log tắt | 2 | 4.777,73 | 3,446 | 1,671 | 11,548 | 0 | 73,16 / 74,12 | 0,87 | 313,0 | 232,5 |
| access_log tắt | 3 | 4.764,28 | 3,636 | 1,745 | 12,626 | 0 | 72,93 / 74,44 | 1,79 | 312,9 | 173,7 |

## So sánh trong cùng phiên (500 VU)

| Chỉ số | access_log bật (TB 3 lượt) | access_log tắt (TB 3 lượt) | Chênh |
| --- | ---: | ---: | ---: |
| RPS | 4.684,1 | 4.762,5 | +1,7% |
| avg ms | 5,16 | 3,68 | -29% |
| p95 ms | 18,24 | 12,76 | -30% |
| CPU Server % | 77,7 | 73,2 | -4,5 điểm |

## Kết luận

- Trong cùng một phiên, `access_log off` chỉ tăng RPS khoảng **2%** (4.684 lên 4.763), nằm trong khoảng dao động giữa các lượt (lượt `access_log` bật số 3 là 4.748, cao hơn lượt tắt số 1 là 4.745). Độ trễ p95 giảm khoảng 30% và CPU Server giảm khoảng 4,5 điểm; các lượt có xu hướng nghiêng về phía `access_log` tắt nhưng chỉ ba lượt mỗi bên, chưa đủ để khẳng định chắc.
- Mức cải thiện **28%** thấy khi so với bộ "trước" ngày 2026-11-19 (3.717 RPS) phần lớn là do môi trường dao động giữa hai phiên, **không** nên quy cho `access_log`. Bộ "trước" đó không dùng được làm mốc so sánh cho các thử nghiệm tiếp theo; mốc đúng là `access_log` bật trong cùng phiên (bảng trên).
- Trong phiên này, `access_log` bật cho 4.684 RPS ở 500 VU, gần giống lượt Bước 1 buổi chiều 19/11 (4.722 RPS) và khác xa phiên 19/11 16:50 (3.717 RPS).
- Ghi đĩa giảm từ khoảng 530 KiB/s xuống dưới 3 KiB/s khi tắt log, nhưng ổ đĩa không phải nút thắt (I/O gần như không đáng kể).
- Chưa điền `conditions.md`, chưa chụp Grafana.
