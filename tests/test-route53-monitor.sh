#!/usr/bin/env bash
set -u

script_path=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/rotute53-demo.sh
temporary_directory=$(mktemp -d "${TMPDIR:-/tmp}/route53-test.XXXXXX") || exit 1
trap 'rm -rf -- "$temporary_directory"' EXIT

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  [[ "$haystack" == *"$needle"* ]] || fail "expected output to contain: $needle"
}

mock_bin="$temporary_directory/bin"
mkdir -p "$mock_bin"
cat > "$mock_bin/curl" <<'MOCK'
#!/usr/bin/env bash
set -u
printf 'called\n' >> "$CURL_CALL_LOG"
header_path=""
for ((index = 1; index <= $#; index++)); do
  if [[ "${!index}" == "--dump-header" ]]; then
    next=$((index + 1))
    header_path="${!next}"
    break
  fi
done
case "${MOCK_CURL_MODE:-success}" in
  success)
    printf 'HTTP/1.1 200 OK\r\nsErVeR: voting-backend/1.2\r\n\r\n' > "$header_path"
    printf '200\t0.012345'
    exit 0
    ;;
  missing_server)
    printf 'HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\n\r\n' > "$header_path"
    printf '200\t0.010000'
    exit 0
    ;;
  http_error)
    printf 'HTTP/1.1 503 Service Unavailable\r\nServer: maintenance\r\n\r\n' > "$header_path"
    printf '503\t0.020000'
    exit 0
    ;;
  curl_failure|timeout)
    : > "$header_path"
    if [[ "$MOCK_CURL_MODE" == timeout ]]; then
      printf 'curl: (28) Operation timed out\n' >&2
      exit 28
    fi
    printf 'curl: (6) Could not resolve host\n' >&2
    exit 6
    ;;
  *)
    printf 'unexpected mock mode\n' >&2
    exit 99
    ;;
esac
MOCK
chmod +x "$mock_bin/curl"

export PATH="$mock_bin:$PATH"
export CURL_CALL_LOG="$temporary_directory/curl-calls"
: > "$CURL_CALL_LOG"

help_output=$(bash "$script_path" --help) || fail "help should succeed"
assert_contains "$help_output" "Usage:"
[[ ! -s "$CURL_CALL_LOG" ]] || fail "help unexpectedly invoked curl"

if bash "$script_path" --count 0 https://example.test >"$temporary_directory/invalid.out" 2>&1; then
  fail "zero count should be rejected"
fi
if bash "$script_path" ftp://example.test >"$temporary_directory/invalid-url.out" 2>&1; then
  fail "unsupported URL scheme should be rejected"
fi
if bash "$script_path" --interval nope https://example.test >"$temporary_directory/invalid-number.out" 2>&1; then
  fail "invalid interval should be rejected"
fi
[[ ! -s "$CURL_CALL_LOG" ]] || fail "invalid arguments unexpectedly invoked curl"

output=$(bash "$script_path" --interval 1 --count 3 --timeout 4 https://example.test) || fail "successful polling failed"
assert_contains "$output" '[1] '
assert_contains "$output" '[2] '
assert_contains "$output" '[3] '
assert_contains "$output" 'status=200 time=0.012345s server="voting-backend/1.2"'
[[ $(wc -l < "$CURL_CALL_LOG") -eq 3 ]] || fail "request count was not finite and exact"

: > "$CURL_CALL_LOG"
MOCK_CURL_MODE=missing_server output=$(MOCK_CURL_MODE=missing_server bash "$script_path" --count 1 https://example.test) || fail "missing Server header should not fail"
assert_contains "$output" 'server="(missing)"'

: > "$CURL_CALL_LOG"
if MOCK_CURL_MODE=http_error bash "$script_path" --count 2 https://example.test >"$temporary_directory/http-error.out" 2>&1; then
  fail "HTTP 503 should produce nonzero final status"
fi
[[ $(wc -l < "$CURL_CALL_LOG") -eq 2 ]] || fail "HTTP error prematurely stopped polling"
assert_contains "$(cat "$temporary_directory/http-error.out")" 'status=503'

for mode in curl_failure timeout; do
  : > "$CURL_CALL_LOG"
  if MOCK_CURL_MODE="$mode" bash "$script_path" --interval 1 --count 2 https://example.test >"$temporary_directory/$mode.out" 2>&1; then
    fail "$mode should produce nonzero final status"
  fi
  [[ $(wc -l < "$CURL_CALL_LOG") -eq 2 ]] || fail "$mode prematurely stopped polling"
  assert_contains "$(cat "$temporary_directory/$mode.out")" 'curl error'
done

: > "$CURL_CALL_LOG"
if bash "$script_path" https://example.test --count 1 >"$temporary_directory/late-option.out" 2>&1; then
  fail "unexpected late option handling"
fi
[[ ! -s "$CURL_CALL_LOG" ]] || fail "invalid option unexpectedly invoked curl"

# The monitor's unique temp directory must be removed after a completed run.
before=$(find "${TMPDIR:-/tmp}" -maxdepth 1 -type d -name 'route53-monitor.*' | wc -l)
bash "$script_path" --count 1 https://example.test >/dev/null || fail "cleanup check request failed"
after=$(find "${TMPDIR:-/tmp}" -maxdepth 1 -type d -name 'route53-monitor.*' | wc -l)
[[ "$before" -eq "$after" ]] || fail "monitor temporary directory was not cleaned up"

printf 'All Route 53 monitor tests passed.\n'
