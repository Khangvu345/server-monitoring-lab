#!/usr/bin/env python3
"""Tổng hợp đúng cửa sổ đo từ các mẫu k6, dùng thư viện chuẩn Python."""
import argparse
import csv
import gzip
import json
import math
import statistics
from datetime import datetime, timezone
from pathlib import Path


def parse_time(value):
    return datetime.fromisoformat(value.replace('Z', '+00:00')).timestamp()


def percentile(sorted_values, fraction):
    pos = (len(sorted_values) - 1) * fraction
    lower = math.floor(pos)
    upper = math.ceil(pos)
    return sorted_values[lower] + (sorted_values[upper] - sorted_values[lower]) * (pos - lower)


def iso(seconds):
    return datetime.fromtimestamp(seconds, timezone.utc).isoformat(timespec='milliseconds').replace('+00:00', 'Z')


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('run_dir', type=Path)
    parser.add_argument('summary_csv', type=Path)
    parser.add_argument('run_id')
    parser.add_argument('vus', type=int)
    parser.add_argument('duration_s', type=int)
    args = parser.parse_args()
    path = args.run_dir / 'samples.ndjson.gz'

    # Hai lượt đọc tuần tự để tránh giữ toàn bộ NDJSON trong RAM.
    starts = []
    with gzip.open(path, 'rt', encoding='utf-8') as stream:
        for line in stream:
            item = json.loads(line)
            if item.get('type') == 'Point' and item.get('metric') == 'lab_scenario_start_ms':
                starts.append(float(item['data']['value']) / 1000.0)
    if len(starts) != 1 or args.duration_s <= 0:
        raise ValueError(f'Cần đúng một mốc k6 bắt đầu; tìm thấy {len(starts)}')
    start = starts[0]
    end = start + args.duration_s
    durations = []
    error_count = zero_status = after_window = 0
    status_counts = {}
    with gzip.open(path, 'rt', encoding='utf-8') as stream:
        for line in stream:
            item = json.loads(line)
            if item.get('type') != 'Point' or item.get('metric') != 'lab_request_ms':
                continue
            data = item['data']
            timestamp = parse_time(data['time'])
            if timestamp >= end:
                after_window += 1
                continue
            if timestamp < start:
                continue
            tags = data.get('tags') or {}
            if tags.get('valid') not in ('true', 'false') or 'lab_status' not in tags:
                raise ValueError('Mẫu thiếu nhãn valid/lab_status')
            value = float(data['value'])
            if not math.isfinite(value) or value < 0:
                raise ValueError('Thời gian phản hồi không hợp lệ')
            durations.append(value)
            error_count += tags['valid'] == 'false'
            status = tags['lab_status']
            status_counts[status] = status_counts.get(status, 0) + 1
            zero_status += status == '0'

    count = len(durations)
    if not count:
        raise ValueError('Không có request hoàn tất trong cửa sổ đo')
    durations.sort()
    # k6 có thể không có duration ý nghĩa khi lỗi kết nối. Không biến 0 thành latency tốt.
    latency = {} if zero_status else {
        'avg_ms': round(statistics.fmean(durations), 4),
        'p50_ms': round(percentile(durations, 0.50), 4),
        'p95_ms': round(percentile(durations, 0.95), 4),
    }
    row = {
        'run_id': args.run_id,
        'vus': args.vus,
        'start_utc': iso(start),
        'end_utc': iso(end),
        'duration_s': args.duration_s,
        'request_count': count,
        'rps': round(count / args.duration_s, 4),
        'error_count': error_count,
        'error_pct': round(100 * error_count / count, 4),
        'avg_ms': latency.get('avg_ms', ''),
        'p50_ms': latency.get('p50_ms', ''),
        'p95_ms': latency.get('p95_ms', ''),
        'status_zero_count': zero_status,
        'after_window_count': after_window,
        'note': 'Khong du latency tin cay do status=0' if zero_status else '',
    }
    output = dict(row, http_status_counts=status_counts)
    (args.run_dir / 'summary.json').write_text(json.dumps(output, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    new_file = not args.summary_csv.exists()
    with args.summary_csv.open('a', newline='', encoding='utf-8') as stream:
        writer = csv.DictWriter(stream, fieldnames=row.keys())
        if new_file:
            writer.writeheader()
        writer.writerow(row)
    print(json.dumps(output, ensure_ascii=False, indent=2))


if __name__ == '__main__':
    main()
