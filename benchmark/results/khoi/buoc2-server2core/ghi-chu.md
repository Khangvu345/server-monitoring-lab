# Bước 2: VM Server tăng từ 1 lên 2 vCPU (Test giữ 4 vCPU)

Ngày chạy: 2026-11-19 (UTC), sau Bước 1 (`../buoc1-test4core/`). Chỉ chạy 1000 VU, hai lượt (probe, làm nóng 30 s, đo 120 s).

## Cấu hình

| VM | vCPU | Ghi chú |
| --- | ---: | --- |
| Server | **2** | đổi từ 1; 1 socket × 2 cores; `worker_processes auto`, xác nhận 2 worker Nginx |
| Monitoring | 2 | không đổi |
| Test | 4 | 2 sockets × 2 cores, không đổi so với Bước 1 |

## Kết quả k6

| Cấu hình | Lượt | RPS | Lỗi | avg ms | p50 ms | p95 ms |
| --- | --- | ---: | ---: | ---: | ---: | ---: |
| Server 1 vCPU (Bước 1) | 1 | 5.007 | 90 (0,015%) | để trống (có status=0) | | |
| **Server 2 vCPU** | 1 | 1.451 | 0 | 584,0 | 518,3 | 1.083,7 |
| **Server 2 vCPU** | 2 | 1.529 | 1 (0,0005%) | để trống (có status=0) | | |

Lượt 2 có 1 request `status=0` nên không điền latency của cửa sổ (theo quy ước analyzer). Toàn tiến trình k6 lượt 1: avg 584 ms, p95 1,08 s, max 8,54 s.

## Kết quả bổ sung: 500 VU (Server 2 vCPU)

Chạy thêm 1 lượt 500 VU (14:13:57 đến 14:15:57 UTC) để xem hiện tượng có xuất hiện ở tải vừa không.

| Cấu hình | VU | RPS | Lỗi | avg ms | p50 ms | p95 ms | CPU Server | CPU Nginx | TCP retransmit | CPU VM Test | k6 |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | --- | --- | ---: | --- | --- |
| Server 1 vCPU (Bước 1) | 500 | 4.722 | 0 | 4,53 | 2,04 | 15,74 | 78% / 81% | 76% / 78% | chưa lấy | 53% / 63% | 208% / 248% |
| **Server 2 vCPU** | 500 | **4.332** | 0 | 13,23 | 3,06 | **60,90** | 48,8% / 50,4% | 78,3% / 84,2% | 3.549/s (max 5.578/s) | 61% / 66% | 227% / 246% |

Ở 500 VU, 2 vCPU cũng kém hơn 1 vCPU: RPS thấp hơn khoảng 8%, p95 cao gấp khoảng 4 lần, dù Server chỉ dùng 49% CPU. Lưu lượng ra 287 MiB/s, retransmit 3.549 segment/s. Hiện tượng không chỉ riêng ở 1000 VU. Một lượt duy nhất, chưa biết dao động giữa các lượt.

## Thử nghiệm: tắt TSO/GSO trên Server (500 VU, Server 2 vCPU)

Lệnh `sudo ethtool -K ens33 tso off gso off` (tạm thời, đã khôi phục `on` sau khi đo). Một lượt 500 VU, 14:28:32 đến 14:30:32 UTC.

| Cấu hình (500 VU, Server 2 vCPU) | RPS | avg ms | p50 ms | p95 ms | CPU Server | CPU Nginx | Retransmit /s | Lưu lượng ra | Gói ra /s |
| --- | ---: | ---: | ---: | ---: | --- | --- | ---: | ---: | ---: |
| TSO/GSO bật (mặc định) | 4.332 | 13,2 | 3,1 | 60,9 | 49% | 78% | 3.549 | 287 MiB/s | chưa lấy |
| TSO/GSO tắt | **1.840** | 169,9 | 183,4 | 249,2 | 44% | 19% | 4.276 | 120 MiB/s | 84.246 |

Tắt TSO/GSO làm RPS giảm hơn một nửa và p95 tăng gấp 4, nên giả thuyết "TSO/GSO là nguyên nhân" **bị bác bỏ**; ngược lại TSO/GSO đang giúp. Kết quả cũng cho thấy khi số gói gửi ra tăng (84 nghìn gói/s) thì thông lượng giảm, nhất quán với việc mạng ảo của VMware hay mất gói khi bị dồn nhiều gói nhỏ. Đây vẫn là suy luận, chưa kiểm chứng trực tiếp.

Sau thử nghiệm đã khôi phục TSO/GSO về `on`. Dòng `tx-tcp6-segmentation: off [requested on]` là tính năng IPv6 TSO không bật được; chưa kiểm tra trạng thái trước thử nghiệm của dòng này (chỉ ghi lại các dòng TSO/GSO IPv4), nên chưa chắc nó có thay đổi do lệnh hay không.

## Tài nguyên trong cửa sổ đo (Server 2 vCPU)

| Lượt | CPU Server tổng avg / max | CPU Nginx avg / max (trên 2 core) | CPU VM Test tổng avg / max | k6 avg / max |
| --- | --- | --- | --- | --- |
| 1 | 36,0% / 38,4% | 13,1% / 14,2% | 41% / 44% | 132% / 141% |
| 2 | 34,8% / 36,1% | 13,0% / 13,4% | 40% / 46% | 130% / 141% |

## Kết luận: kết quả không thể hiện tác dụng của vCPU

Tăng Server lên 2 vCPU làm RPS **giảm** từ 5.007 xuống khoảng 1.450 đến 1.530, dù CPU của Server (khoảng 36%) và VM Test (khoảng 40%) đều còn dư nhiều. Hai lượt giống nhau, nên không phải dao động ngẫu nhiên. Không nên kết luận "tăng CPU làm chậm hơn": CPU không phải yếu tố giới hạn ở đây.

So sánh Server trong cửa sổ Bước 1 (1 vCPU) và Bước 2 (2 vCPU, lượt 2), số liệu Prometheus:

| Chỉ số Server | 1 vCPU | 2 vCPU |
| --- | ---: | ---: |
| Lưu lượng gửi ra (MiB/s) | 341 | 100 |
| TCP retransmit (segment/s) | 914 | 7.926 |
| Ngắt phần cứng (/s) | 12.675 | 4.610 |
| Context switch (/s) | 300 | 1.626 |
| softirq trung bình | 27,5% | 30,5% |
| Gói rớt ở card mạng của guest (cả hai VM) | 0 | 0 |

- Tỷ lệ gửi lại gói TCP tăng khoảng 9 lần (khoảng 11% số gói ở 2 vCPU), nên thông lượng giảm dù CPU rảnh.
- Mọi ngắt của card mạng `e1000` (IRQ 19) nằm trên core 0, core 1 gần như rảnh (softirq core 0 khoảng 61%, core 1 khoảng 3%; idle core 1 khoảng 91%).
- Card mạng của cả hai guest báo 0 gói rớt, nên chỗ mất gói nằm ngoài guest, trong lớp mạng ảo của VMware (VMnet8/NAT) hoặc cơ chế mô phỏng `e1000`. Chưa xác định chính xác nguyên nhân.

## Điều chưa kiểm chứng

- Chưa rõ vì sao 2 vCPU gây mất gói nhiều hơn. Có thể liên quan lập lịch vCPU của host hoặc mô phỏng card mạng `e1000`; đây là giả thuyết, chưa được thử.
- Chưa chạy lại 1 vCPU sau khi VM Server khởi động lại, nên chưa loại trừ ảnh hưởng của việc khởi động lại hoặc trạng thái host.
- Chưa chạy 500 VU ở Server 2 vCPU.
- Một số lượt rất ít (hai lượt), chưa lặp theo quy trình 3 lượt.

## Tệp

- `phan-tich-tong-hop.csv`, `log/vu1000-lan0{1,2}-k6.log` và `-warmup.log`, `raw-run-info/probe_vu1000_lan0{1,2}/`.
- Mẫu thô còn trên VM Test: `~/ket-qua-benchmark/20261119T133944Z_probe_nmHDRZ` và `20261119T134426Z_probe_nLlWKu`.
