# Building and Maintaining grpc-web

## Building grpcwebproxy Binary

### Prerequisites
- Go 1.24+
- Git

### Build from Source

```bash
cd go/grpcwebproxy
go build -o grpcwebproxy .
./grpcwebproxy --help
```

### Build for Specific Platform

```bash
# Linux
GOOS=linux GOARCH=amd64 go build -o grpcwebproxy-linux-amd64 .

# macOS
GOOS=darwin GOARCH=amd64 go build -o grpcwebproxy-darwin-amd64 .
GOOS=darwin GOARCH=arm64 go build -o grpcwebproxy-darwin-arm64 .

# Windows
GOOS=windows GOARCH=amd64 go build -o grpcwebproxy.exe .
```

## Updating Go Dependencies

### When to Update
- Security vulnerabilities (CVEs) discovered
- New Go version released
- Bug fixes in dependencies

### Update Process

1. **Update Go version** (if needed)
   ```bash
   # Edit go.mod and change:
   go 1.24.0
   ```

2. **Update specific packages**
   ```bash
   # Update to specific version
   go get -u google.golang.org/grpc@v1.56.3
   
   # Update to latest
   go get -u golang.org/x/net@latest
   ```

3. **Update all dependencies**
   ```bash
   go get -u ./...
   ```

4. **Clean up**
   ```bash
   go mod tidy
   ```

5. **Verify build**
   ```bash
   cd go/grpcwebproxy
   go build .
   ./grpcwebproxy --help
   ```

6. **Commit changes**
   ```bash
   git add go.mod go.sum
   git commit -m "Update dependencies to fix CVEs"
   git push origin master
   ```

### Common CVE Fixes

Recent security updates:

| Package | Vulnerable Version | Fixed Version | CVEs |
|---------|-------------------|---------------|------|
| golang.org/x/net | <0.1.1 | 0.48.0+ | CVE-2022-41721, CVE-2022-27664 |
| google.golang.org/grpc | <1.56.3 | 1.56.3+ | CVE-2023-44487, GHSA-m425-mq94-257g |
| github.com/sirupsen/logrus | <1.8.3 | 1.9.3+ | CVE-2025-65637 |
| golang.org/x/text | <0.3.8 | 0.32.0+ | CVE-2022-32149 |
| google.golang.org/protobuf | <1.33.0 | 1.33.0+ | CVE-2024-24786 |

### Check for Vulnerabilities

```bash
# Using go tooling
go list -json -m all | go-mod-vulnerability-check

# Or use Docker Scout (recommended)
docker build -t grpcwebproxy-test .
docker scout cves grpcwebproxy-test
```

## Building Docker Image

See [BUILD_DOCKER.md](BUILD_DOCKER.md) for building secure Docker images with Chainguard base images.

Quick reference:
```bash
# Build locally
./build.sh

# Build and push to ECR
./build.sh --push --aws-profile prod

# Build with CVE scan
./build.sh --scan
```

## Running Tests

```bash
# Run all tests
go test ./...

# Run tests with coverage
go test -cover ./...

# Run tests for specific package
go test ./go/grpcweb/...
```

## Client Libraries

### JavaScript/TypeScript

```bash
cd client/grpc-web
npm install
npm run build
npm test
```

### React Example

```bash
cd client/grpc-web-react-example
npm install
npm start
```

## Troubleshooting

### Build Fails After Dependency Update

```bash
# Clear module cache
go clean -modcache

# Re-download dependencies
go mod download

# Verify and tidy
go mod verify
go mod tidy
```

### Import Errors

```bash
# Ensure all imports are correct after updates
go get -u ./...
go mod tidy
```

### Version Conflicts

If you see "requires X but have Y" errors:

```bash
# Check dependency graph
go mod graph | grep <package>

# Update conflicting package
go get -u <package>@<version>
```

## Release Checklist

1. Update dependencies and fix CVEs
2. Run tests: `go test ./...`
3. Build binary: `go build ./go/grpcwebproxy`
4. Build Docker image: `./build.sh --scan`
5. Verify 0 CVEs in scan results
6. Push to ECR: `./build.sh --push`
7. Update K8s deployments with new image tag
8. Verify services are healthy after deployment
