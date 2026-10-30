# Hướng dẫn cài đặt k6 bằng script `install-k6.sh`

## 1. Mục đích

Script `install-k6.sh` cài đặt **Grafana k6 đúng phiên bản 2.3.0** trên VM Test. k6 không có trong kho APT chính thức của Ubuntu, nên script tự thêm kho APT chính thức của Grafana (`dl.k6.io`) kèm khóa ký trước khi cài. Script ghim cứng phiên bản 2.3.0: nếu kho không có đúng phiên bản này, script dừng và báo lỗi chứ không cài phiên bản khác.

## 2. Điều kiện trước khi chạy

- Chạy trên **VM Test** (máy phát tải), hệ điều hành Ubuntu hoặc Debian, kiến trúc amd64 hoặc arm64.
- Có quyền `sudo` (script yêu cầu quyền root).
- VM có kết nối Internet trong lúc cài để tải khóa ký và gói k6.
- File `install-k6.sh` nằm cùng thư mục với tài liệu này (`scripts/test/`).

## 3. Cách chạy

Đứng tại thư mục chứa script:

```bash
cd scripts/test
sudo bash install-k6.sh
```

Hoặc, sau khi đã cấp quyền thực thi, chạy trực tiếp:

```bash
chmod +x install-k6.sh
sudo ./install-k6.sh
```

> **Không chạy bằng `sh install-k6.sh`.** Trên Ubuntu, `sh` là Dash chứ không phải Bash; Dash không hỗ trợ `pipefail` nên script sẽ dừng ngay ở dòng 6 với lỗi `set: Illegal option -o pipefail`. Đây là lỗi gọi sai trình thông dịch, không phải lỗi quyền file.

## 4. Kết quả mong đợi

Trong lúc chạy, script in các dòng `[INFO]` theo từng bước: cài gói phụ thuộc, thêm khóa ký, thêm kho APT, làm mới metadata, cài gói k6. Xen giữa là các dòng của `apt` — đó là bình thường.

Cài thành công khi cuối màn hình hiện:

```text
[INFO] Cài đặt thành công.
k6 v2.3.0 (commit/…, go…, linux/amd64)
```

Kiểm chứng lại bất cứ lúc nào bằng lệnh:

```bash
k6 version
```

## 5. Các trường hợp thường gặp

| Hiện tượng | Ý nghĩa / cách xử lý |
|---|---|
| Chạy lại script và thấy `k6 2.3.0 đã được cài đặt; không cần làm gì thêm.` | Bình thường — script nhận ra đúng phiên bản đã có và thoát sớm. Script chạy lại nhiều lần an toàn. |
| `set: Illegal option -o pipefail` | Đang chạy bằng `sh` (Dash). Chạy lại bằng `sudo bash install-k6.sh`. |
| `Hãy chạy script này bằng sudo hoặc với quyền root.` | Chưa có quyền root. Chạy lại kèm `sudo`. |
| `Không tìm thấy k6 2.3.0 cho kiến trúc …` | Kho Grafana không phục vụ phiên bản 2.3.0 cho kiến trúc của máy này, hoặc VM mất mạng khi cập nhật APT. Kiểm tra kết nối rồi chạy lại. |
| `Kiểm tra phiên bản thất bại: cần 2.3.0, nhận được …` | Gói đã cài nhưng phiên bản thực tế khác 2.3.0. Ghi lại toàn bộ dòng lỗi khi báo cáo. |
| Thông báo tiếng Việt hiển thị thiếu dấu trên màn hình VM | Giới hạn font của console thuần chữ trên Ubuntu Server, không phải lỗi file hay lỗi script. Xem qua SSH từ máy host sẽ hiển thị đủ dấu. |

## 6. Ghi chú

- Script chỉ cài k6; việc viết kịch bản tải và chạy benchmark thuộc các file khác trong thư mục `benchmark/k6/` và `scripts/test/`.
- Mọi dòng lỗi của script đều bắt đầu bằng `[ERROR]` — khi cần hỗ trợ, gửi đúng dòng `[ERROR]` đó kèm lệnh đã chạy.
