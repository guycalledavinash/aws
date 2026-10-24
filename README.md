## Hello there, checkout my AWS projects.

## Route 53 failover endpoint monitor

`rotute53-demo.sh` periodically makes finite HTTP requests to a URL and prints the response status, elapsed request time, and the backend's `Server` response header. It does not change Route 53 records or DNS configuration. It requires Bash, curl, and standard utilities (`awk`, `date`, `sleep`, and `mktemp`).

Run it with an HTTP or HTTPS URL:

```bash
bash rotute53-demo.sh --interval 3 --count 5 --timeout 8 https://example.com
```

Options are `--interval` (seconds between checks, default 5; range 1–3600), `--count` (maximum requests, default 10; range 1–1000), and `--timeout` (curl connection and total timeout in seconds, default 10; range 1–120). Use `--help` for usage. Invalid arguments fail before curl is invoked. Each line is numbered and timestamped and includes the HTTP status, response time, and Server header (or `(missing)`). HTTP error statuses (400+) and curl failures are reported, polling continues to the configured count, and the command exits nonzero if any request failed. A missing Server header alone is informational.

You can use repeated observations to see which backend the endpoint returned as DNS answers change. These results only show what each HTTP request received; they do not prove that Route 53 itself performed a failover. Resolver and client DNS caching, TTLs, and existing connections can delay when a DNS change becomes visible.

The script can be tested offline with the mocked-curl test harness:

```bash
bash tests/test-route53-monitor.sh
```
