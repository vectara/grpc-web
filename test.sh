#!/bin/bash
set -e

echo "======================================="
echo "Testing grpcwebproxy"
echo "======================================="
echo ""

# Test 1: Run grpcweb library tests
echo "1. Running grpcweb library tests..."
cd go/grpcweb
go test ./...
cd ../..
echo ""

# Test 2: Build grpcwebproxy
echo "2. Building grpcwebproxy..."
cd go/grpcwebproxy
go build -o /tmp/grpcwebproxy-test .
cd ../..
echo "   ✓ grpcwebproxy built successfully"
rm -f /tmp/grpcwebproxy-test
echo ""

echo "======================================="
echo "✓ All tests passed!"
echo "======================================="
