# Hướng dẫn cài đặt k6 (script `install-k6.sh` hoặc cài thủ công)

## 1. Mục đích

Cài đặt **Grafana k6 đúng phiên bản 2.3.0** trên VM Test. k6 không có trong kho APT chính thức của Ubuntu, nên cần thêm kho APT chính thức của Grafana (`dl.k6.io`) kèm khóa ký trước khi cài. Phiên bản được ghim cứng ở 2.3.0: kho không có đúng phiên bản này thì dừng lại chứ không cài phiên bản khác.

Có hai cách cài, cho cùng một kết quả:

- **Cách 1 (mục 3):** chạy script `install-k6.sh` — script tự làm mọi bước và tự kiểm tra.
- **Cách 2 (mục 4):** gõ thủ công từng lệnh tương đương — dùng khi muốn tự kiểm soát từng bước hoặc khi script không chạy được.

## 2. Điều kiện trước khi cài

- Chạy trên **VM Test** (máy phát tải), hệ điều hành Ubuntu hoặc Debian, kiến trúc amd64 hoặc arm64 (kiểm tra bằng `dpkg --print-architecture`).
- Có quyền `sudo`.
- VM có kết nối Internet trong lúc cài để tải khóa ký và gói k6.
- Nếu dùng Cách 1: file `install-k6.sh` nằm cùng thư mục với tài liệu này (`scripts/test/`).

## 3. Cách 1 — Chạy script

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

## 4. Cách 2 — Cài thủ công bằng dòng lệnh

Các lệnh dưới đây làm đúng từng bước script làm. Chạy lần lượt, bằng tài khoản có quyền `sudo`:

**Bước 1 — Cài các gói phụ thuộc:**

```bash
sudo apt-get update
sudo apt-get install -y --no-install-recommends ca-certificates curl gnupg
```

**Bước 2 — Thêm khóa ký APT chính thức của k6:**

```bash
sudo install -d -m 0755 /usr/share/keyrings
curl -fsSL https://dl.k6.io/key.gpg | sudo gpg --dearmor --yes -o /usr/share/keyrings/k6-archive-keyring.gpg
sudo chmod 0644 /usr/share/keyrings/k6-archive-keyring.gpg
```

**Bước 3 — Thêm kho APT của k6:**

```bash
echo "deb [signed-by=/usr/share/keyrings/k6-archive-keyring.gpg] https://dl.k6.io/deb stable main" | sudo tee /etc/apt/sources.list.d/k6.list
sudo chmod 0644 /etc/apt/sources.list.d/k6.list
```

**Bước 4 — Làm mới metadata và kiểm tra kho có đúng phiên bản 2.3.0:**

```bash
sudo apt-get update
apt-cache madison k6
```

Trong kết quả của `apt-cache madison k6` phải có một dòng phiên bản bắt đầu bằng `2.3.0` (dạng đầy đủ kiểu `2.3.0+really2.3.0...` tùy kho). Không có thì dừng tại đây — không cài phiên bản khác.

**Bước 5 — Cài đúng phiên bản 2.3.0:**

```bash
sudo apt-get install -y --no-install-recommends --allow-downgrades "k6=<phiên bản đầy đủ>"
```

Thay `<phiên bản đầy đủ>` bằng đúng chuỗi phiên bản 2.3.0 thấy ở Bước 4. Cờ `--allow-downgrades` cho phép hạ cấp nếu máy đang có sẵn một bản k6 khác.


**Bước 6 — Kiểm chứng:**

```bash
k6 version
```

Kết quả phải bắt đầu bằng `k6 v2.3.0`. Khác số này là chưa đúng bản cần dùng.

> Khác biệt duy nhất so với script: script tự kiểm tra hệ điều hành/kiến trúc, tự nhận diện khi k6 2.3.0 đã có sẵn (và bỏ qua), còn cài thủ công thì người chạy tự để ý các điểm đó.

## 5. Kết quả mong đợi

Nếu dùng script, trong lúc chạy script in các dòng `[INFO]` theo từng bước: cài gói phụ thuộc, thêm khóa ký, thêm kho APT, làm mới metadata, cài gói k6. Xen giữa là các dòng của `apt` — đó là bình thường. Cài thủ công thì không có dòng `[INFO]`, chỉ có đầu ra của từng lệnh.

Cài thành công khi lệnh kiểm chứng cho kết quả:

```text
k6 v2.3.0 (commit/…, go…, linux/amd64)
```

(Script in thêm dòng `[INFO] Cài đặt thành công.` ngay trước kết quả này.) Kiểm chứng lại bất cứ lúc nào bằng lệnh `k6 version`.

## 6. Các trường hợp thường gặp

| Hiện tượng | Ý nghĩa / cách xử lý |
|---|---|
| Chạy lại script và thấy `k6 2.3.0 đã được cài đặt; không cần làm gì thêm.` | Bình thường — script nhận ra đúng phiên bản đã có và thoát sớm. Script chạy lại nhiều lần an toàn. |
| `set: Illegal option -o pipefail` | Đang chạy script bằng `sh` (Dash). Chạy lại bằng `sudo bash install-k6.sh`. |
| `Hãy chạy script này bằng sudo hoặc với quyền root.` | Chưa có quyền root. Chạy lại kèm `sudo`. |
| `Không tìm thấy k6 2.3.0 cho kiến trúc …` (script) hoặc `apt-cache madison k6` không có dòng 2.3.0 (thủ công) | Kho Grafana không phục vụ phiên bản 2.3.0 cho kiến trúc của máy này, hoặc VM mất mạng khi cập nhật APT. Kiểm tra kết nối rồi làm lại. |
| `Kiểm tra phiên bản thất bại: cần 2.3.0, nhận được …` | Gói đã cài nhưng phiên bản thực tế khác 2.3.0. Ghi lại toàn bộ dòng lỗi khi báo cáo. |
| Thông báo tiếng Việt hiển thị thiếu dấu trên màn hình VM | Giới hạn font của console thuần chữ trên Ubuntu Server, không phải lỗi file hay lỗi script. Xem qua SSH từ máy host sẽ hiển thị đủ dấu. |

## 7. Ghi chú

- Tài liệu này chỉ lo việc cài k6; việc viết kịch bản tải và chạy benchmark thuộc các file khác trong thư mục `benchmark/k6/` và `scripts/test/`.
- Mọi dòng lỗi của script đều bắt đầu bằng `[ERROR]` — khi cần hỗ trợ, gửi đúng dòng `[ERROR]` đó kèm lệnh đã chạy.
