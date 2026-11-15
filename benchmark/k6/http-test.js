// Một VU tải một tệp, chờ 100 ms rồi lặp lại.
import http from 'k6/http';
import { sleep } from 'k6';
import exec from 'k6/execution';
import { Gauge, Trend } from 'k6/metrics';

const url = __ENV.TARGET_URL;
const vus = Number(__ENV.TEST_VUS || 1);
const seconds = Number(__ENV.TEST_DURATION_S || 15);
if (!url || !Number.isInteger(vus) || vus < 1 || !Number.isInteger(seconds) || seconds < 1) {
  throw new Error('Thiếu TARGET_URL hoặc TEST_VUS / TEST_DURATION_S không hợp lệ');
}

export const options = {
  throw: false,
  scenarios: {
    benchmark: {
      executor: 'constant-vus',
      vus: vus,
      duration: `${seconds}s`,
      // Cho request đến 10 giây hoàn thành, tránh ngắt request cuối lượt.
      // Mẫu hoàn thành sau cửa sổ chính thức bị loại khi tổng hợp.
      gracefulStop: '12s',
    },
  },
  summaryTrendStats: ['avg', 'med', 'p(95)', 'min', 'max'],
};

const scenarioStart = new Gauge('lab_scenario_start_ms');
const requestDuration = new Trend('lab_request_ms', true);

export default function () {
  // Dấu mốc theo đồng hồ VM Test, chỉ phát một lần cho cả tiến trình k6.
  if (exec.scenario.iterationInInstance === 0) {
    scenarioStart.add(exec.scenario.startTime);
  }

  const res = http.get(url, {
    headers: { 'Accept-Encoding': 'identity' },
    redirects: 0,
    timeout: '10s',
    responseType: 'binary',
  });
  const valid = res.status === 200 && res.body !== null && res.body.byteLength === 65536;

  // Một mẫu cho mỗi request đã trở về, kể cả mã lỗi hoặc sai kích thước.
  // status=0 là lỗi kết nối/timeout; bộ tổng hợp sẽ cảnh báo latency không tin cậy.
  requestDuration.add(res.timings.duration, {
    valid: valid ? 'true' : 'false',
    lab_status: String(res.status),
  });
  sleep(0.1);
}
