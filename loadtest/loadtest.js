import { check, sleep } from "k6";
import http from "k6/http";
import { Counter } from "k6/metrics";

const LOADTEST_URL = __ENV.LOADTEST_URL || "http://localhost:3000/add";
const LOADTEST_VUS = __ENV.LOADTEST_VUS || 1000;
const LOADTEST_ITERATIONS = __ENV.LOADTEST_ITERATIONS || 1000;
const LOADTEST_DURATION = __ENV.LOADTEST_DURATION || "10s";

export const options = {
  // vus: LOADTEST_VUS,
  // iterations: LOADTEST_ITERATIONS,
  // duration: LOADTEST_DURATION,

  // stages: [
  //   { duration: "1m", target: 10000 },
  //   { duration: "1m", target: 0 },
  // ],

  vus: 20000,
  duration: "1m",
};

const status500Rate = new Counter("status_500_rate");

export default function () {
  const res = http.get(LOADTEST_URL);
  check(res, { "status was 200": (r) => r.status === 200 });

  if (res.status === 500) {
    status500Rate.add(1);
  }
  
  // run once
  sleep(1000);
}
