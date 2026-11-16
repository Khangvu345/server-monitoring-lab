#!/usr/bin/env bash
# Điều khiển smoke, pilot và đo chính thức. Chạy trên VM Test, không cần sudo.
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"
K6_SCRIPT="$REPO_ROOT/benchmark/k6/http-test.js"
ANALYZER="$REPO_ROOT/benchmark/analysis/analyze-results.py"
CONDITIONS_TEMPLATE="$REPO_ROOT/benchmark/conditions.example.md"
EXPECTED_SHA="7daca2095d0438260fa849183dfc67faa459fdf4936e1bc91eec6b281b27e4c2"
EXPECTED_SIZE=65536
COOLDOWN_S=60
current_dir=''

usage() {
  cat <<'EOF'
Cách chạy trên VM Test:
  bash scripts/test/run-benchmark.sh smoke 'http://IP_SERVER/benchmark/payload.bin'
  bash scripts/test/run-benchmark.sh pilot 'http://IP_SERVER/benchmark/payload.bin'
  bash scripts/test/run-benchmark.sh probe 'http://IP_SERVER/benchmark/payload.bin' VU
  bash scripts/test/run-benchmark.sh official 'http://IP_SERVER/benchmark/payload.bin' THAP TRUNG_BINH CAO

smoke: 1 VU, 15 giây; pilot: 1, 5, 15 VU, mỗi mức một lần;
probe: thăm dò thêm một mức; official: mỗi mức đã chốt lặp 3 lần.
Kết quả ghi vào ~/ket-qua-benchmark/ (hoặc BENCH_RESULT_ROOT nếu được đặt).
EOF
}
die() { printf '\n[LỖI] %s\n' "$*" >&2; [[ -z "$current_dir" ]] || printf 'Dữ liệu đã ghi: %s\n' "$current_dir" >&2; exit 1; }
now() { date -u '+%Y-%m-%dT%H:%M:%S.%3NZ'; }
stamp() { printf '[%s] %s\n' "$(now)" "$*"; }

[[ $# -ge 2 ]] || { usage; exit 1; }
MODE="$1"
TARGET_URL="$2"
shift 2
case "$MODE" in
  smoke) [[ $# -eq 0 ]] || die 'smoke không nhận thêm tham số.'; levels=(1); repeat=1; warmup=0; duration=15 ;;
  pilot) [[ $# -eq 0 ]] || die 'pilot không nhận thêm tham số.'; levels=(1 5 15); repeat=1; warmup=30; duration=120 ;;
  probe) [[ $# -eq 1 ]] || die 'probe cần đúng một số VU.'; levels=("$1"); repeat=1; warmup=30; duration=120 ;;
  official) [[ $# -eq 3 ]] || die 'official cần ba số VU đã chốt.'; levels=("$1" "$2" "$3"); repeat=3; warmup=30; duration=120 ;;
  *) usage; exit 1 ;;
esac
[[ "$TARGET_URL" =~ ^http://[^[:space:]]+/benchmark/payload\.bin$ ]] || die 'URL phải là http://IP_SERVER/benchmark/payload.bin, không kèm dấu / cuối.'
for n in "${levels[@]}"; do
  [[ "$n" =~ ^[1-9][0-9]*$ ]] || die 'VU phải là số nguyên dương.'
  (( n <= 10000 )) || die 'VU quá lớn; cần xem lại mức tải.'
done
if [[ "$MODE" == official ]]; then
  (( levels[0] < levels[1] && levels[1] < levels[2] )) || die 'Ba mức official phải theo thứ tự tăng dần: thấp, trung bình, cao.'
fi
for c in k6 curl python3 sha256sum stat date awk mktemp tee sleep; do
  command -v "$c" >/dev/null 2>&1 || die "Thiếu chương trình: $c"
done
[[ -f "$K6_SCRIPT" && -f "$ANALYZER" && -f "$CONDITIONS_TEMPLATE" ]] || die 'Thiếu file trong bộ script.'

RESULT_ROOT="${BENCH_RESULT_ROOT:-$HOME/ket-qua-benchmark}"
mkdir -p -- "$RESULT_ROOT"
BATCH_DIR="$(mktemp -d "$RESULT_ROOT/$(date -u +%Y%m%dT%H%M%SZ)_${MODE}_XXXXXX")"
current_dir="$BATCH_DIR"
cp -- "$CONDITIONS_TEMPLATE" "$BATCH_DIR/conditions.md"
{
  printf 'Thời điểm thu thập UTC: '; now
  printf 'Chế độ: %s\nĐích: %s\nMức VU: %s\nLặp/mức: %s\n' "$MODE" "$TARGET_URL" "${levels[*]}" "$repeat"
  printf 'Làm nóng/đo/nghỉ (giây): %s/%s/%s\n' "$warmup" "$duration" "$COOLDOWN_S"
  printf 'SHA-256 kỳ vọng: %s\n\n' "$EXPECTED_SHA"
  printf '%s\n' '--- Phiên bản k6 ---'; k6 version
  printf '\n%s\n' '--- VM Test ---'; uname -a; hostname
  if command -v uptime >/dev/null 2>&1; then uptime; fi
  if command -v free >/dev/null 2>&1; then free -h; fi
  if command -v ip >/dev/null 2>&1; then ip -br address 2>&1 || true; fi
  if command -v timedatectl >/dev/null 2>&1; then timedatectl 2>&1 || true; fi
  printf '\n%s\n' '--- Dấu vân tay các script ---'
  sha256sum "$K6_SCRIPT" "$SCRIPT_DIR/run-benchmark.sh" "$ANALYZER"
} > "$BATCH_DIR/conditions-automatic.txt"

check_payload() {
  local label="$1" dir="$2" tmp info code size hash
  tmp="$(mktemp "$dir/payload-check.XXXXXX")"
  if ! info="$(curl -sS --connect-timeout 5 --max-time 10 -H 'Accept-Encoding: identity' -o "$tmp" -w '%{http_code}' "$TARGET_URL" 2>"$dir/curl-${label}-errors.txt")"; then
    rm -f -- "$tmp"
    die "Không tải được payload ($label); xem $dir/curl-${label}-errors.txt"
  fi
  code="$info"
  size="$(stat -c '%s' "$tmp")"
  hash="$(sha256sum "$tmp" | awk '{print $1}')"
  rm -f -- "$tmp"
  {
    printf 'Thời gian UTC: %s\nURL: %s\n' "$(now)" "$TARGET_URL"
    printf 'HTTP: %s\nSố byte: %s\nSHA-256: %s\nSHA-256 kỳ vọng: %s\n' "$code" "$size" "$hash" "$EXPECTED_SHA"
  } > "$dir/check-${label}.txt"
  [[ "$code" == 200 && "$size" == "$EXPECTED_SIZE" && "$hash" == "$EXPECTED_SHA" ]] || die "Payload $label không đạt: HTTP=$code, byte=$size, SHA-256=$hash. Xem $dir/check-${label}.txt"
  stamp "Kiểm tra $label: HTTP 200, đủ 65.536 byte, SHA-256 khớp."
}

confirm_baseline() {
  local answer
  printf '\nXem Grafana/VM Test: CPU và mạng đã về gần mức nghỉ; không mất dữ liệu.\n'
  printf 'Nhấn Enter để tiếp tục, hoặc Ctrl+C để dừng: '
  IFS= read -r answer || die 'Không nhận được xác nhận từ người chạy.'
}

run_one() {
  local vus="$1" iteration="$2" run_name dir rc
  printf -v run_name '%s_vu%s_lan%02d' "$MODE" "$vus" "$iteration"
  dir="$BATCH_DIR/$run_name"
  mkdir -- "$dir"
  current_dir="$dir"
  stamp "Bắt đầu $run_name"
  check_payload before "$dir"
  if (( warmup > 0 )); then
    stamp "Làm nóng ${warmup}s với $vus VU."
    if k6 run --quiet -e "TARGET_URL=$TARGET_URL" -e "TEST_VUS=$vus" \
      -e "TEST_DURATION_S=$warmup" "$K6_SCRIPT" >"$dir/warmup.log" 2>&1; then :
    else die "Làm nóng thất bại, xem $dir/warmup.log"; fi
  fi
  now > "$dir/process-start-utc.txt"
  stamp "Đo ${duration}s với $vus VU; đang lưu mẫu..."
  if k6 run --quiet --out "json=$dir/samples.ndjson.gz" \
    -e "TARGET_URL=$TARGET_URL" -e "TEST_VUS=$vus" -e "TEST_DURATION_S=$duration" \
    "$K6_SCRIPT" >"$dir/k6.log" 2>&1; then rc=0; else rc=$?; fi
  now > "$dir/process-end-utc.txt"
  if (( rc != 0 )); then
    die "k6 dừng với mã $rc. Xem $dir/k6.log; lượt này chưa được nghiệm thu."
  fi
  check_payload after "$dir"
  if ! python3 "$ANALYZER" "$dir" "$BATCH_DIR/summary.csv" "$run_name" "$vus" "$duration"; then
    die "Không thể tổng hợp $run_name; giữ lại dữ liệu gốc để kiểm tra."
  fi
  if [[ "$MODE" == smoke ]]; then
    if ! python3 -c 'import json,sys; sys.exit(0 if json.load(open(sys.argv[1], encoding="utf-8"))["error_count"] == 0 else 1)' "$dir/summary.json"; then
      die 'Smoke có request không hợp lệ; xử lý trước khi chạy pilot.'
    fi
  fi
  stamp "Đã lưu $run_name tại $dir"
}

stamp "Thư mục kết quả: $BATCH_DIR"
stamp 'Kiểm tra conditions.md: điều kiện host, ba VM, phiên bản, card mạng, đĩa và tình trạng nền.'
printf 'Nhấn Enter sau khi đã ghi điều kiện vào file trên, hoặc Ctrl+C để dừng: '
IFS= read -r answer || die 'Không nhận được xác nhận về điều kiện thực nghiệm.'
if [[ "$MODE" != smoke ]]; then
  stamp "Nghỉ ít nhất ${COOLDOWN_S}s trước lượt đầu để tránh ảnh hưởng từ lần chạy trước."
  sleep "$COOLDOWN_S"
  confirm_baseline
fi

total=$(( ${#levels[@]} * repeat ))
done_count=0
for vus in "${levels[@]}"; do
  for (( i=1; i<=repeat; i++ )); do
    run_one "$vus" "$i"
    done_count=$((done_count + 1))
    if (( done_count < total )); then
      stamp "Nghỉ ít nhất ${COOLDOWN_S}s; kiểm tra Grafana và VM Test."
      sleep "$COOLDOWN_S"
      confirm_baseline
    fi
  done
done
current_dir="$BATCH_DIR"
stamp "Hoàn tất các lượt. Bảng: $BATCH_DIR/summary.csv"
stamp 'Tiếp tục kiểm tra dữ liệu Prometheus/Grafana, bổ sung conditions.md và ghi sự cố nếu có.'
