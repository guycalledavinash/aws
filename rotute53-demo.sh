#!/usr/bin/env bash
# Poll an HTTP endpoint and display its status, response time, and Server header.

set -u
set -o pipefail

usage() {
  cat <<'USAGE'
Usage:
  bash rotute53-demo.sh [options] URL

Poll an HTTP/HTTPS URL a finite number of times. A dry monitoring request is
made once per interval; the script never changes Route 53 or DNS configuration.

Options:
  -i, --interval SECONDS  Delay between requests (1-3600; default: 5)
  -n, --count NUMBER      Maximum requests (1-1000; default: 10)
  -t, --timeout SECONDS   Curl connection and total timeout (1-120; default: 10)
  -h, --help              Show this help and exit

Examples:
  bash rotute53-demo.sh https://example.com
  bash rotute53-demo.sh --interval 3 --count 5 --timeout 8 https://example.com
USAGE
}

argument_error() {
  printf 'Error: %s\n' "$1" >&2
  printf 'Try --help for usage.\n' >&2
  exit 2
}

validate_integer() {
  local variable_name="$1"
  local label="$2"
  local value="$3"
  local minimum="$4"
  local maximum="$5"
  local normalized

  if [[ ! "$value" =~ ^[0-9]+$ ]] || (("${#value}" > 9)); then
    argument_error "$label must be an integer from $minimum to $maximum"
  fi

  normalized=$((10#$value))
  if ((normalized < minimum || normalized > maximum)); then
    argument_error "$label must be an integer from $minimum to $maximum"
  fi

  printf -v "$variable_name" '%d' "$normalized"
}

poll_interval=5
max_requests=10
request_timeout=10
target_url=""
url_set=0

while (($# > 0)); do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    -i|--interval)
      (($# >= 2)) || argument_error "$1 requires a value"
      poll_interval="$2"
      shift 2
      ;;
    --interval=*)
      poll_interval="${1#*=}"
      shift
      ;;
    -n|--count)
      (($# >= 2)) || argument_error "$1 requires a value"
      max_requests="$2"
      shift 2
      ;;
    --count=*)
      max_requests="${1#*=}"
      shift
      ;;
    -t|--timeout)
      (($# >= 2)) || argument_error "$1 requires a value"
      request_timeout="$2"
      shift 2
      ;;
    --timeout=*)
      request_timeout="${1#*=}"
      shift
      ;;
    --)
      shift
      while (($# > 0)); do
        if ((url_set != 0)); then
          argument_error "only one target URL may be supplied"
        fi
        target_url="$1"
        url_set=1
        shift
      done
      ;;
    -*)
      argument_error "unknown option: $1"
      ;;
    *)
      if ((url_set != 0)); then
        argument_error "only one target URL may be supplied"
      fi
      target_url="$1"
      url_set=1
      shift
      ;;
  esac
done

((url_set != 0)) || argument_error "a target URL is required"
validate_integer poll_interval "polling interval" "$poll_interval" 1 3600
validate_integer max_requests "request count" "$max_requests" 1 1000
validate_integer request_timeout "request timeout" "$request_timeout" 1 120

case "$target_url" in
  http://*|https://*) ;;
  *) argument_error "URL scheme must be http or https" ;;
esac

authority="${target_url#*://}"
authority="${authority%%[/?#]*}"
if [[ -z "$authority" || "$target_url" == *[$' \t\r\n']* ]]; then
  argument_error "target URL must include a host and contain no whitespace"
fi

for required_command in curl awk date sleep mktemp; do
  if ! command -v "$required_command" >/dev/null 2>&1; then
    printf 'Error: required command not found: %s\n' "$required_command" >&2
    exit 1
  fi
done

umask 077
temporary_directory=$(mktemp -d "${TMPDIR:-/tmp}/route53-monitor.XXXXXX") || {
  printf 'Error: could not create a temporary directory.\n' >&2
  exit 1
}
headers_file="$temporary_directory/headers"
curl_error_file="$temporary_directory/curl-error"
: > "$headers_file"
: > "$curl_error_file"

request_number=0
overall_status=0

cleanup() {
  if [[ -n "${temporary_directory:-}" && -d "$temporary_directory" ]]; then
    rm -rf -- "$temporary_directory"
  fi
}

handle_interrupt() {
  printf '\nInterrupted after %d request(s).\n' "$request_number" >&2
  exit 130
}

trap cleanup EXIT
trap handle_interrupt INT

while ((request_number < max_requests)); do
  request_number=$((request_number + 1))
  timestamp=$(date '+%Y-%m-%d %H:%M:%S %z')
  : > "$headers_file"
  : > "$curl_error_file"

  curl_result=""
  if curl_result=$(curl --silent --show-error --location \
    --connect-timeout "$request_timeout" \
    --max-time "$request_timeout" \
    --dump-header "$headers_file" \
    --output /dev/null \
    --write-out $'%{http_code}\t%{time_total}' \
    "$target_url" 2>"$curl_error_file"); then
    curl_status=0
  else
    curl_status=$?
  fi

  http_status="000"
  response_time="unknown"
  IFS=$'\t' read -r http_status response_time <<< "$curl_result"
  [[ -n "$http_status" ]] || http_status="000"
  [[ -n "$response_time" ]] || response_time="unknown"

  server_header=$(awk '
    /^HTTP\// { server = ""; next }
    {
      line = $0
      sub(/\r$/, "", line)
      colon = index(line, ":")
      if (colon > 0 && tolower(substr(line, 1, colon - 1)) == "server") {
        value = substr(line, colon + 1)
        sub(/^[ \t]+/, "", value)
        sub(/[ \t]+$/, "", value)
        server = value
      }
    }
    END { if (server != "") print server }
  ' "$headers_file")
  [[ -n "$server_header" ]] || server_header="(missing)"

  printf '[%d] %s status=%s time=%ss server="%s"\n' \
    "$request_number" "$timestamp" "$http_status" "$response_time" "$server_header"

  if ((curl_status != 0)); then
    overall_status=1
    curl_error=$(< "$curl_error_file")
    printf '  curl error (%d): %s\n' "$curl_status" "${curl_error:-no diagnostic provided}" >&2
  fi

  if [[ "$http_status" =~ ^[0-9]{3}$ ]] && ((10#$http_status >= 400)); then
    overall_status=1
    printf '  HTTP request returned an error status.\n' >&2
  elif [[ "$http_status" == "000" ]]; then
    overall_status=1
  fi

  if ((request_number < max_requests)); then
    sleep "$poll_interval"
  fi
done

if ((overall_status == 0)); then
  printf 'Completed %d request(s) without HTTP or curl errors.\n' "$request_number"
else
  printf 'Completed %d request(s); one or more HTTP or curl failures occurred.\n' \
    "$request_number" >&2
fi

exit "$overall_status"
