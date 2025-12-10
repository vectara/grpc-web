#!/bin/sh
set -e

# Default values
HTTP_PORT=${HTTP_PORT:-8090}
BACKEND_SERVER=${BACKEND_SERVER:-localhost}
BACKEND_PORT=${BACKEND_PORT:-9090}
BACKEND_TLS=${BACKEND_TLS:-false}

# Build backend address
BACKEND_ADDR="${BACKEND_SERVER}:${BACKEND_PORT}"

# Execute grpcwebproxy with environment-based configuration
exec /usr/local/bin/grpcwebproxy \
  --backend_addr="${BACKEND_ADDR}" \
  --backend_tls="${BACKEND_TLS}" \
  --run_tls_server=false \
  --server_http_debug_port="${HTTP_PORT}" \
  --allow_all_origins
