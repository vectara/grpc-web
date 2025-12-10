# Building grpcwebproxy Docker Image

Build and push grpcwebproxy as a secure, minimal container using Chainguard images.

## Prerequisites

### Required Tools

1. **Docker** (20.10+)
2. **AWS CLI** (v2) 
3. **Git**
4. **chainctl** - Chainguard CLI for registry access
   ```bash
   # Login to Chainguard
   chainctl auth login
   
   # Verify access to Vectara images
   chainctl images repos list --output table | grep vectara
   ```

5. **Docker Scout** (optional, for CVE scanning)
   ```bash
   # Usually included with Docker Desktop, or install:
   curl -sSfL https://raw.githubusercontent.com/docker/scout-cli/main/install.sh | sh -s --
   ```

### AWS Setup

1. **Configure AWS profile** with ECR access
   ```bash
   aws configure list --profile <your-profile>
   ```

2. **Create ECR repository** (if it doesn't exist)
   ```bash
   aws ecr create-repository \
     --repository-name ext/grpcwebproxy \
     --profile <your-profile> \
     --region <your-region>
   ```

## Quick Start

### Build locally
```bash
./build.sh
```

### Build and push to ECR
```bash
./build.sh --push
```

### Build, scan, and push
```bash
./build.sh --push --scan
```

## Usage Examples

```bash
# Custom tag
./build.sh --tag v0.15.1-secure --push

# Specific AWS profile and region
./build.sh --push --aws-profile prod --aws-region us-east-1

# Build without pushing
./build.sh --scan
```

### Environment Variables

```bash
export AWS_PROFILE=prod
export AWS_REGION=us-east-1
./build.sh --push
```

## Build Script Options

| Option | Description | Default |
|--------|-------------|---------|
| `--push` | Push image to ECR | `false` |
| `--scan` | Run Docker Scout CVE scan | `false` |
| `--tag TAG` | Override auto-generated tag | `<sha>-<date>` |
| `--aws-profile` | AWS profile to use | `$AWS_PROFILE` or `default` |
| `--aws-region` | AWS region | `$AWS_REGION` or `us-west-2` |
| `--ecr-repo` | ECR repository name | `ext/grpcwebproxy` |
| `-h, --help` | Show help | - |

## Docker Image Details

**Multi-Stage Build:**
1. Build stage: Compiles grpcwebproxy as static binary with latest Go
2. Runtime stage: Minimal Chainguard static image (~10-20MB)

**Security Features:**
- No shell, package manager, or unnecessary binaries
- Latest Go stdlib and dependencies
- Runs as non-root user
- Chainguard images with minimal CVEs

## Troubleshooting

**Cannot pull Chainguard images:**
```bash
chainctl auth login
chainctl images list --repo go --output table
```

**ECR push fails:**
```bash
aws sts get-caller-identity --profile <profile>
aws ecr describe-repositories --repository-names ext/grpcwebproxy
```

**Build fails:**
```bash
cd go/grpcwebproxy
go mod tidy
```

## Verification

```bash
# Check image size
docker images | grep grpcwebproxy

# Run CVE scan
docker scout cves <image-name>

# Test the binary
docker run --rm <image-name> --help
```

## Updating K8s Deployments

After building, update the image tag in provisioning repo:

```yaml
# k8s-deploy/charts/core/{sycamore,hollyoak,titan-inc}/values.yaml
grpcwebproxy:
  image:
    repository: ext/grpcwebproxy
    tag: <new-tag>  # e.g., a3b4c5d-20251211
```
