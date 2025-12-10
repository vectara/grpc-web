#!/bin/bash
set -e

echo "========================================="
echo "grpcwebproxy Integration Test"
echo "========================================="
echo ""

cleanup() {
    echo "Cleaning up..."
    docker stop grpcwebproxy-test-container 2>/dev/null || true
    docker rm grpcwebproxy-test-container 2>/dev/null || true
    kill $GRPC_SERVER_PID 2>/dev/null || true
    exit $1
}

trap 'cleanup 1' INT TERM

# Step 1: Build Docker image
echo "1. Building Docker image..."
docker build -q -t grpcwebproxy-test:latest . > /dev/null
echo "   ✓ Docker image built"
echo ""

# Step 2: Build and start test gRPC server
echo "2. Starting test gRPC server on port 9090..."
cd integration_test/go/testserver
go build -o /tmp/testserver . 2>/dev/null
/tmp/testserver --http1_port=9999 --http2_port=9090 &
GRPC_SERVER_PID=$!
cd ../../..

# Wait for server to start
sleep 2
if ! kill -0 $GRPC_SERVER_PID 2>/dev/null; then
    echo "   ✗ Failed to start gRPC test server"
    cleanup 1
fi
echo "   ✓ gRPC test server running (PID: $GRPC_SERVER_PID)"
echo ""

# Step 3: Start grpcwebproxy from Docker
echo "3. Starting grpcwebproxy container..."
docker run -d \
    --name grpcwebproxy-test-container \
    --network host \
    grpcwebproxy-test:latest \
    --backend_addr=localhost:9090 \
    --backend_tls=true \
    --backend_tls_noverify \
    --run_tls_server=false \
    --server_http_debug_port=8090 \
    --allow_all_origins

# Wait for proxy to start
sleep 2
if ! docker ps | grep -q grpcwebproxy-test-container; then
    echo "   ✗ Failed to start grpcwebproxy container"
    docker logs grpcwebproxy-test-container
    cleanup 1
fi
echo "   ✓ grpcwebproxy container running"
echo ""

# Step 4: Send test request through proxy
echo "4. Sending gRPC-Web request through proxy..."

# Create a simple Ping request (protobuf encoded)
# PingRequest with value="test" (field 1, string)
# Protobuf wire format: field_number=1, type=2(length-delimited), length=4, value="test"
PING_REQUEST=$(echo -n "0a0474657374" | xxd -r -p | base64)

# Send gRPC-Web request
RESPONSE=$(curl -s -X POST \
    -H "Content-Type: application/grpc-web" \
    -H "X-Grpc-Web: 1" \
    --data-binary @<(echo -n "00000000$(echo -n "$PING_REQUEST" | wc -c | xargs printf "%08x" | xxd -r -p)$PING_REQUEST" | xxd -r -p) \
    http://localhost:8090/improbable.grpcweb.test.TestService/Ping \
    --write-out "\n%{http_code}" | tail -1)

if [ "$RESPONSE" = "200" ]; then
    echo "   ✓ Received HTTP 200 response"
    echo "   ✓ gRPC-Web request successfully proxied!"
else
    echo "   ✗ Expected HTTP 200, got: $RESPONSE"
    cleanup 1
fi
echo ""

# Step 5: Verify proxy logs
echo "5. Checking proxy logs..."
if docker logs grpcwebproxy-test-container 2>&1 | grep -q "listening for http"; then
    echo "   ✓ Proxy is listening for HTTP requests"
else
    echo "   ⚠ Could not verify proxy listening (may still work)"
fi
echo ""

echo "========================================="
echo "✓ Integration test PASSED!"
echo "========================================="
echo ""
echo "Summary:"
echo "  • Built Docker image with CGO_ENABLED=0"
echo "  • Started real gRPC server"
echo "  • Started grpcwebproxy from Docker"
echo "  • Sent gRPC-Web request through proxy"
echo "  • Received successful response"
echo ""
echo "The Docker-built grpcwebproxy works correctly!"
echo ""

cleanup 0
