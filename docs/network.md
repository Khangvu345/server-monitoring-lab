# Thiết kế mạng

## 1. Mô hình

Ba VM kết nối vào **cùng một VMnet NAT** trong VMware Virtual Network Editor. Không tạo ba mạng NAT độc lập nếu mục tiêu là để các VM giao tiếp trực tiếp trong cùng subnet.

NAT cho phép VM sử dụng kết nối mạng thông qua Host/gateway NAT. Bridge là chế độ đưa VM tham gia mạng LAN vật lý như một thiết bị trong mạng đó. Dự án chọn NAT để tạo mạng lab riêng và vẫn có thể truy cập mạng ngoài qua NAT.

## 2. Địa chỉ IP 
Kiểm tra subnet và gateway trong Virtual Network Editor, tránh trùng với mạng đang dùng và thiết lập như sau.

| VM | Hostname | IP dự kiến |
|---|---|---|
| Server | server | 192.168.100.10/24 |
| Monitoring | monitoring | 192.168.100.20/24 |
| Test | test | 192.168.100.30/24 |

| Thuộc tính | Giá trị |
|---|---|
| VMnet | Vmnet8 - NAT |
| Subnet | 192.168.100.0/24 |
| Gateway NAT | 192.168.100.2 |
| DNS | Auto |
| DHCP | Không dùng, địa chỉ IP tĩnh |

## 3. Luồng kết nối và cổng

| Nguồn | Đích | Giao thức/cổng | Mục đích |
|---|---|---|---|
| VM Test | VM Server | TCP 80 | HTTP load test |
| VM Monitoring | VM Server | TCP 9100 | Prometheus scrape Node Exporter |
| VM Monitoring | VM Server | TCP 9256 | Prometheus scrape process-exporter (metrics theo tiến trình) |
| Host | VM Monitoring | TCP 3000 | Truy cập Grafana |
| Host | Các VM | TCP 22 | SSH quản trị, nếu bật |

Chỉ cho phép nguồn cần thiết truy cập từng cổng. Không mở Node Exporter ra mạng không tin cậy.

## 4. Kiểm tra sau cấu hình

Trên từng VM:

```bash
ip -br address
ip route
resolvectl status
```

Kiểm tra kết nối giữa các VM:

```bash
ping -c 4 192.168.100.10
ping -c 4 192.168.100.20
ping -c 4 192.168.100.30
```

Thay địa chỉ theo IP thực tế đã chốt. Ping có thể bị chặn bởi firewall; nếu ping thất bại, kiểm tra route, IP, VMnet và firewall trước khi kết luận VM không kết nối được.


