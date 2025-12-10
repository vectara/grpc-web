# Build stage - use Chainguard Go builder
# To update versions: chainctl images list --repo go --output table
ARG REGISTRY=cgr.dev/vectara.com
FROM ${REGISTRY}/go:1.25.5 AS builder

WORKDIR /workspace

COPY go.mod go.sum ./
RUN go mod download

COPY go/ ./go/
COPY client/ ./client/

WORKDIR /workspace/go/grpcwebproxy

RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
    -ldflags="-w -s" \
    -o /grpcwebproxy \
    .

# Runtime stage - use Chainguard base for shell support
# To update: chainctl images list --repo chainguard-base --output table
FROM ${REGISTRY}/chainguard-base:v20230214

COPY --from=builder /grpcwebproxy /usr/local/bin/grpcwebproxy
COPY entrypoint.sh /entrypoint.sh

USER nonroot:nonroot

ENTRYPOINT ["/entrypoint.sh"]
