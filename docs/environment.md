# Môi trường triển khai

## 1. Nền tảng

| Thuộc tính | Giá trị |
|---|---|
| Hypervisor | VMware |
| Guest OS | Ubuntu Server – version 24.04.5 LTS |
| Kiến trúc CPU | x86_64 |
| Network | Một mạng NAT chung |
| Disk provisioning | --- |

## 2. Cấu hình máy ảo

| VM | vCPU | RAM | Disk | Dịch vụ |
|---|---:|---:|---:|---|
| Server | 1 | 1.5 GB | 10 GB | Nginx, Node Exporter, process-exporter |
| Monitoring | 2 | 2 GB | 10 GB | Prometheus, Grafana |
| Test | 2 | 1.5 GB | 10 GB | k6 |

Tổng cấp phát: 5 vCPU, 5 GB RAM, 30 GB dung lượng đĩa ảo.

## 3. Thông tin máy Host

Điền thông tin của máy thực hiện benchmark:

| Thuộc tính | Giá trị |
|---|---|
| CPU | --- |
| RAM | 16GB |
| Ổ đĩa lưu VM | --- |
| Hệ điều hành Host | Window |
| VMware version | Workstation Pro version 25H2 |
| Tình trạng ứng dụng nền khi benchmark | --- |

## 4. Quản lý phiên bản


| Thành phần | Phiên bản thực tế | Nguồn cài đặt | Người cập nhật |
|---|---|---|---|
| Ubuntu Server | 24.04.5  | https://ubuntu.com/download/server | Khang |
| Nginx | 1.24.0 | apt (Ubuntu 24.04) | TODO |
| Node Exporter | 1.12.1 | https://github.com/prometheus/node_exporter/releases/tag/v1.12.1 | TODO |
| process-exporter | 0.8.7 | https://github.com/ncabatoff/process-exporter/releases/tag/v0.8.7 | TODO |
| Prometheus | TODO | TODO | TODO |
| Grafana | TODO | TODO | TODO |
| k6 | TODO | TODO | TODO |

## 5. Nguyên tắc tái lập

- Dùng cùng ISO và phiên bản Ubuntu cho cả nhóm.
- Ghi lại phiên bản VMware và cấu hình phần cứng VM.
- Lưu script, file cấu hình và hướng dẫn cài đặt trong repository.
- Ghi lại phiên bản package/binary, nguồn tải và checksum khi phù hợp.
- Kiểm thử quy trình trên VM Ubuntu mới trước khi xác nhận có thể triển khai lại.
