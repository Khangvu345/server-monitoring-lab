# Thiết lập nền dùng chung

Script `setup-common.sh` chạy trên **cả ba VM** (Server, Monitoring, Test) trước khi cài dịch vụ theo vai trò. Ubuntu Server 24.04.5 LTS.

## Vì sao cần

Khi kiểm thử, VM Test tạo request, VM Server ghi access log, VM Monitoring vẽ tải trên dashboard. Ba nguồn này chỉ đối chiếu được nếu đồng hồ ba VM giống nhau. Script đặt cùng múi giờ và bật đồng bộ NTP trên mọi VM.

## Script làm gì

| Việc | Chi tiết |
|---|---|
| Múi giờ | `Asia/Ho_Chi_Minh` (đổi bằng `TIMEZONE`), phải giống nhau trên cả ba VM |
| Đồng bộ thời gian | Bật NTP qua `systemd-timesyncd`, máy chủ `ntp.ubuntu.com` (đổi bằng `NTP_SERVERS`); chờ đến khi `NTPSynchronized=yes` |
| Hostname | Đặt theo `VM_HOSTNAME` (`server`, `monitoring` hoặc `test`) |
| `/etc/hosts` | Thêm tên cho ba VM theo IP của lab; chạy lại thì thay khối cũ |
| Gói tiện ích | `curl`, `wget`, `ca-certificates`, `gnupg`, `openssh-server`; bật SSH |

Script **không** cấu hình IP (xem mục 2 của [`docs/server-manual-setup.md`](../../docs/server-manual-setup.md)), không bật firewall (mỗi vai trò có luật riêng trong script của vai trò đó), và không tạo tài khoản hay mật khẩu.

## Chạy script

Trên từng VM, từ thư mục `scripts/common` trong repo:

```bash
chmod +x setup-common.sh
sudo VM_HOSTNAME=server ./setup-common.sh       # trên VM Server
sudo VM_HOSTNAME=monitoring ./setup-common.sh   # trên VM Monitoring
sudo VM_HOSTNAME=test ./setup-common.sh         # trên VM Test
```

| Biến | Mặc định | Ý nghĩa |
|---|---|---|
| `VM_HOSTNAME` | (bắt buộc) | `server`, `monitoring` hoặc `test` |
| `TIMEZONE` | `Asia/Ho_Chi_Minh` | Múi giờ, phải giống nhau trên cả ba VM |
| `NTP_SERVERS` | `ntp.ubuntu.com` | Máy chủ NTP, cách nhau bởi khoảng trắng |
| `SERVER_IP` | `192.168.100.10` | IP VM Server trong `/etc/hosts` |
| `MONITORING_IP` | `192.168.100.20` | IP VM Monitoring trong `/etc/hosts` |
| `TEST_IP` | `192.168.100.30` | IP VM Test trong `/etc/hosts` |

Script chạy lại an toàn: ghi đè file cấu hình timesyncd và khối trong `/etc/hosts`, không nhân đôi.

## Kiểm tra

Trên từng VM:

```bash
timedatectl
# Time zone: Asia/Ho_Chi_Minh (+07, +0700)
# System clock synchronized: yes
# NTP service: active

timedatectl timesync-status
```

So sánh đồng hồ giữa các VM: chạy lệnh dưới đây gần như cùng lúc trên ba VM, thời điểm phải lệch nhau không quá vài trăm mili giây.

```bash
date -Is
```

Chạy lại bước này trước mỗi lượt đo và sau khi khởi động lại VM hoặc revert snapshot.

## Khi script lỗi

- `Chưa đồng bộ được NTP`: VM không ra Internet. Kiểm tra `ping ntp.ubuntu.com`, gateway và DNS trong netplan, hoặc dùng `NTP_SERVERS` trỏ tới máy chủ NTP có thể truy cập.
- Nếu VMware đang đồng bộ giờ guest theo host (VMware Tools), tắt tùy chọn đó hoặc để cả hai cùng đúng giờ; hai nguồn khác nhau sẽ làm giờ nhảy.
- Xem log: `sudo journalctl -u systemd-timesyncd -n 50`.

## Thứ tự dùng với script khác

1. Đặt IP tĩnh theo `docs/server-manual-setup.md`.
2. Chạy `scripts/common/setup-common.sh` với `VM_HOSTNAME` đúng vai trò.
3. Chạy script theo vai trò: `scripts/server/setup-server.sh` và các script tương ứng cho Monitoring, Test.
