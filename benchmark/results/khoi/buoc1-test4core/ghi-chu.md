# Bước 1: VM Test tăng từ 2 lên 4 vCPU (Server giữ 1 vCPU)

Ngày chạy: 2026-11-19 (UTC), sau baseline ở `../ghi-chu.md`. Cùng script và tham số: `probe`, làm nóng 30 s, đo 120 s, 1 lượt mỗi mức.

## Cấu hình

| VM | vCPU | Ghi chú |
| --- | ---: | --- |
| Server | 1 | không đổi, `worker_processes auto` |
| Monitoring | 2 | không đổi |
| Test | **4** | đổi từ 2. Topology VMware: 2 processors × 2 cores (baseline là 1 processor × 2 cores). RAM 1.3 GiB không đổi |

VM Test vừa bật lại, đợi 2 phút rồi mới đo. Payload hợp lệ trước và sau cả hai lượt.

## Kết quả k6

| Cấu hình | VU | RPS | Lỗi | avg ms | p50 ms | p95 ms |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Test 2 vCPU (baseline) | 500 | 3.880 | 0 | 22,77 | 16,22 | 68,22 |
| **Test 4 vCPU** | 500 | **4.722** | 0 | **4,53** | **2,04** | **15,74** |
| Test 2 vCPU (baseline, lượt 1 / 2) | 1000 | 3.249 / 3.356 | 288 / 513 | để trống | | |
| **Test 4 vCPU** | 1000 | **5.007** | 90 (0,015%) | để trống (có status=0) | | |

## Tài nguyên trong cửa sổ đo

| Mức | CPU Server avg / max | CPU Nginx avg / max | RAM Server | CPU VM Test tổng avg / max | k6 avg / max |
| --- | --- | --- | ---: | --- | --- |
| 500 VU | 78,2% / 81,3% | 75,8% / 77,9% | 29% | 53% / 63% | 208% / 248% |
| 1000 VU | 99,5% / 100% | 97,6% / 98,4% | 30% | 69% / 73% | 266% / 279% |

CPU VM Test lấy từ `top -b -d 5`. CPU Server từ Prometheus, cửa sổ 30 s, bước 5 s.

## Nhận xét

- Tăng VM Test lên 4 vCPU làm RPS ở 500 VU tăng 22% (3.880 lên 4.722) và p95 giảm từ 68 ms xuống 15,7 ms, trong khi Server không đổi. Xác nhận máy phát tải ở 2 vCPU là nút thắt của baseline.
- Ở 500 VU, CPU Server tăng từ khoảng 66% lên 78%: Server được "kéo" nhiều tải hơn.
- Ở 1000 VU, RPS tăng từ khoảng 3.300 lên 5.007, lỗi giảm từ 0,07 đến 0,13% xuống 0,015%. Server đạt 99,5% CPU và Nginx 97,6%, nên ở cấu hình này Server (1 vCPU) mới là nút thắt, VM Test còn dư (CPU tổng 69%).
- Vì vậy baseline có ý nghĩa để so sánh khi đổi vCPU Server là cấu hình này (Test 4 vCPU, Server 1 vCPU), không phải baseline Test 2 vCPU.

## Ghi chú

- Một lượt mỗi mức. Chưa điền `conditions.md`, chưa chụp Grafana.
- Mẫu thô giữ trên VM Test: `~/ket-qua-benchmark/20261119T131637Z_probe_F367UE` và `20261119T132103Z_probe_fN6dV2`; log `top` ở `~/top-vmtest-b1.log`.
