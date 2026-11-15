# BẢNG ÁNH XẠ ĐẠI LƯỢNG GIÁM SÁT – VM1 SERVER

## 1. Tổng quan

Hệ thống sử dụng Prometheus để thu thập dữ liệu giám sát từ VM1 Server thông qua hai exporter:

- **Node Exporter (port 9100):** Thu thập tài nguyên toàn bộ máy chủ.
- **Process Exporter (port 9256):** Thu thập tài nguyên của từng nhóm tiến trình, đặc biệt là Nginx.

Chu kỳ lấy mẫu của hai job `vm1-node` và `vm1-process` được thống nhất là **5 giây**.

## 2. Bảng ánh xạ đại lượng

| Đại lượng | Metric | Đơn vị | Chu kỳ lấy mẫu |
|---|---|---|---|
| CPU Server | `node_cpu_seconds_total` | % | 5s |
| RAM đã sử dụng | `node_memory_MemTotal_bytes`, `node_memory_MemAvailable_bytes` | % | 5s |
| RAM khả dụng | `node_memory_MemAvailable_bytes` | MiB | 5s |
| Disk Read IOPS | `node_disk_reads_completed_total` | ops/s | 5s |
| Disk Write IOPS | `node_disk_writes_completed_total` | ops/s | 5s |
| Nginx CPU | `namedprocess_namegroup_cpu_seconds_total` | % | 5s |
| Nginx RAM | `namedprocess_namegroup_memory_bytes` | MiB | 5s |

## 3. Chi tiết PromQL và cách tính

### 3.1. CPU Server (%)

**Metric:** `node_cpu_seconds_total`

```promql
100 * (1 - avg by(instance) (
  rate(node_cpu_seconds_total{
    instance="192.168.100.10:9100",
    mode="idle"
  }[1m])
))
```

**Cách tính:** Lấy 100% trừ tỷ lệ CPU ở trạng thái idle. Dùng `rate()` để tính tốc độ thay đổi bộ đếm CPU trong một phút.

### 3.2. RAM đã sử dụng (%)

**Metric:**
- `node_memory_MemTotal_bytes`
- `node_memory_MemAvailable_bytes`

```promql
100 * (
  1 -
  node_memory_MemAvailable_bytes{
    instance="192.168.100.10:9100"
  }
  /
  node_memory_MemTotal_bytes{
    instance="192.168.100.10:9100"
  }
)
```

**Cách tính:** Lấy tổng RAM trừ RAM khả dụng, sau đó chia cho tổng RAM và nhân 100.

### 3.3. RAM khả dụng (MiB)

**Metric:** `node_memory_MemAvailable_bytes`

```promql
node_memory_MemAvailable_bytes{
  instance="192.168.100.10:9100"
} / 1024 / 1024
```

**Cách tính:** Chuyển đổi từ byte sang MiB bằng cách chia cho 1024².

### 3.4. Disk Read IOPS

**Metric:** `node_disk_reads_completed_total`

```promql
sum(
  rate(node_disk_reads_completed_total{
    instance="192.168.100.10:9100",
    device!~"loop.*|ram.*"
  }[1m])
)
```

**Cách tính:** Sử dụng `rate()` để tính số thao tác đọc đĩa hoàn thành trung bình mỗi giây trong một phút, sau đó cộng các thiết bị được chọn.

### 3.5. Disk Write IOPS

**Metric:** `node_disk_writes_completed_total`

```promql
sum(
  rate(node_disk_writes_completed_total{
    instance="192.168.100.10:9100",
    device!~"loop.*|ram.*"
  }[1m])
)
```

**Cách tính:** Tính số thao tác ghi đĩa hoàn thành trung bình mỗi giây.

### 3.6. Nginx CPU (%)

**Metric:** `namedprocess_namegroup_cpu_seconds_total`

```promql
100 * sum(
  rate(namedprocess_namegroup_cpu_seconds_total{
    instance="192.168.100.10:9256",
    groupname="nginx"
  }[1m])
)
```

**Cách tính:** Tính tổng tốc độ sử dụng CPU của nhóm tiến trình Nginx, bao gồm thời gian CPU user và system, rồi nhân 100.

Lưu ý: Giá trị có thể vượt 100% khi Nginx sử dụng nhiều hơn một CPU core.

### 3.7. Nginx RAM (MiB)

**Metric:** `namedprocess_namegroup_memory_bytes`

```promql
sum(
  namedprocess_namegroup_memory_bytes{
    instance="192.168.100.10:9256",
    groupname="nginx",
    memtype="resident"
  }
) / 1024 / 1024
```

**Cách tính:** Cộng lượng RAM resident của các tiến trình thuộc nhóm Nginx và chuyển đổi từ byte sang MiB.

## 4. Chu kỳ lấy mẫu và cửa sổ tính toán

| Thành phần | Giá trị |
|---|---|
| vm1-node scrape_interval | 5s |
| vm1-process scrape_interval | 5s |
| Cửa sổ rate() | 1m |
| Đơn vị RAM | MiB |
| Đơn vị IOPS | operations/second |
| Đơn vị CPU | Percent |

**Lưu ý:** Chu kỳ lấy mẫu 5 giây là khoảng thời gian Prometheus thu thập dữ liệu. Cửa sổ `[1m]` là khoảng thời gian dùng để tính tốc độ thay đổi của các metric dạng counter, không phải chu kỳ lấy mẫu.

## 5. Nguồn dữ liệu

| Exporter | Địa chỉ | Vai trò |
|---|---|---|
| Node Exporter | `192.168.100.10:9100` | Giám sát tài nguyên VM1 |
| Process Exporter | `192.168.100.10:9256` | Giám sát tiến trình Nginx |

Prometheus trên VM2 thu thập dữ liệu từ hai endpoint trên và cung cấp dữ liệu cho Grafana để hiển thị Dashboard.

## 6. Kiểm chứng

Có thể kiểm tra metric trực tiếp trên Prometheus tại:

`http://192.168.100.20:9090/graph`

Các job cần có trạng thái UP:

- `vm1-node`
- `vm1-process`

Có thể sử dụng PromQL ở trên để kiểm tra dữ liệu từng đại lượng.
