# 1-million-connection-challenge

try load testing a go application with 1 million concurrent connections
but limited due to cloud quota

each loadtest container will run k6 with 20000 virtual users for 1 minute
try adjust docker-compose.yml to run more loadtest containers (currently replicas: 7)

currently max request achieved is 20000 \* 7 = 140000

## steps to reproduce

1. create VMs on google cloud platform with terraform

```bash
terraform init
terraform apply
```

2. setup swarm by running

```bash
./swarm_setup.sh
```

3. run load test

```bash
./run_test_in_swarm.sh
```

4. teardown setup

```bash
terraform destroy
```

## results

k6 output

```txt
time="2023-12-04T04:56:13Z" level=warning msg="No script iterations fully finished, consider making the test duration longer"

     ✓ status was 200

     checks.........................: 100.00% ✓ 20000      ✗ 0
     data_received..................: 2.5 MB  27 kB/s
     data_sent......................: 1.5 MB  17 kB/s
     http_req_blocked...............: avg=5.21s   min=54.12ms  med=3.47s   max=20.33s   p(90)=11.66s  p(95)=12.11s
     http_req_connecting............: avg=5.19s   min=54.03ms  med=3.43s   max=20.23s   p(90)=11.66s  p(95)=12.1s
     http_req_duration..............: avg=5.51s   min=100.04ms med=5.17s   max=20.37s   p(90)=10.88s  p(95)=13.94s
       { expected_response:true }...: avg=5.51s   min=100.04ms med=5.17s   max=20.37s   p(90)=10.88s  p(95)=13.94s
     http_req_failed................: 0.00%   ✓ 0          ✗ 20000
     http_req_receiving.............: avg=224.5µs min=10.81µs  med=21.35µs max=184.36ms p(90)=45.37µs p(95)=66.88µs
     http_req_sending...............: avg=1.18s   min=23.89µs  med=8.15ms  max=14.8s    p(90)=5.12s   p(95)=5.45s
     http_req_tls_handshaking.......: avg=0s      min=0s       med=0s      max=0s       p(90)=0s      p(95)=0s
     http_req_waiting...............: avg=4.33s   min=1.9ms    med=3.6s    max=11.71s   p(90)=10.42s  p(95)=10.63s
     http_reqs......................: 20000   221.248218/s
     vus............................: 20000   min=0        max=20000
     vus_max........................: 20000   min=1841     max=20000


running (1m30.4s), 00000/20000 VUs, 0 complete and 20000 interrupted iterations
default ✓ [ 100% ] 20000 VUs  1m0s
```

count output ("http://app:3000/get")

```txt
{"count":138449}
```
