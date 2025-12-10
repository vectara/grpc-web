#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
    cat << USAGE
Build and optionally push grpcwebproxy Docker image to ECR

Usage: $0 [OPTIONS]

Options:
    --push              Push image to ECR after building
    --scan              Run Docker Scout CVE scan
    --tag TAG           Override auto-generated tag (default: <short-sha>-<date>)
    --aws-profile PROF  AWS profile to use (default: from AWS_PROFILE env or 'default')
    --aws-region REG    AWS region (default: from AWS_REGION env or 'us-west-2')
    --ecr-repo REPO     ECR repository name (default: 'ext/grpcwebproxy')
    --registry REG      Chainguard registry (default: 'cgr.dev/vectara.com')
    -h, --help          Show this help message

Examples:
    # Build only
    $0

    # Build and push to ECR
    $0 --push

    # Build, scan, and push
    $0 --push --scan

    # Build with custom tag
    $0 --tag v0.15.1 --push

    # Build with specific AWS profile and region
    $0 --push --aws-profile prod --aws-region us-east-1
USAGE
}

PUSH=false
SCAN=false
TAG=""
AWS_PROFILE="${AWS_PROFILE:-default}"
AWS_REGION="${AWS_REGION:-us-west-2}"
ECR_REPO="ext/grpcwebproxy"
CHAINGUARD_REGISTRY="cgr.dev/vectara.com"

while [[ $# -gt 0 ]]; do
    case $1 in
        --push)
            PUSH=true
            shift
            ;;
        --scan)
            SCAN=true
            shift
            ;;
        --tag)
            TAG="$2"
            shift 2
            ;;
        --aws-profile)
            AWS_PROFILE="$2"
            shift 2
            ;;
        --aws-region)
            AWS_REGION="$2"
            shift 2
            ;;
        --ecr-repo)
            ECR_REPO="$2"
            shift 2
            ;;
        --registry)
            CHAINGUARD_REGISTRY="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

cd "$SCRIPT_DIR"

if [ -z "$TAG" ]; then
    SHORT_SHA=$(git rev-parse --short HEAD)
    DATE=$(date +%Y%m%d)
    TAG="${SHORT_SHA}-${DATE}"
fi

AWS_ACCOUNT_ID=$(aws sts get-caller-identity --profile "$AWS_PROFILE" --query Account --output text)
ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
IMAGE_NAME="${ECR_REGISTRY}/${ECR_REPO}:${TAG}"

echo "========================================="
echo "Building grpcwebproxy Docker image"
echo "========================================="
echo "Tag:               $TAG"
echo "Chainguard:        $CHAINGUARD_REGISTRY"
echo "ECR Registry:      $ECR_REGISTRY"
echo "ECR Repository:    $ECR_REPO"
echo "Full Image:        $IMAGE_NAME"
echo "AWS Profile:       $AWS_PROFILE"
echo "AWS Region:        $AWS_REGION"
echo "Push to ECR:       $PUSH"
echo "Run Scout Scan:    $SCAN"
echo "========================================="

echo ""
echo "Building image..."
docker build \
    --build-arg REGISTRY="$CHAINGUARD_REGISTRY" \
    -t "$IMAGE_NAME" \
    -f Dockerfile \
    .

echo ""
echo "✓ Build complete: $IMAGE_NAME"

if [ "$SCAN" = true ]; then
    echo ""
    echo "Running Docker Scout CVE scan..."
    if command -v docker scout &> /dev/null; then
        docker scout cves "$IMAGE_NAME" || echo "Warning: Scout scan found vulnerabilities"
    else
        echo "Warning: docker scout not found. Install with: docker scout --help"
    fi
fi

if [ "$PUSH" = true ]; then
    echo ""
    echo "Logging in to ECR..."
    aws ecr get-login-password --region "$AWS_REGION" --profile "$AWS_PROFILE" | \
        docker login --username AWS --password-stdin "$ECR_REGISTRY"

    echo ""
    echo "Pushing image to ECR..."
    docker push "$IMAGE_NAME"
    
    echo ""
    echo "✓ Push complete: $IMAGE_NAME"
fi

echo ""
echo "========================================="
echo "Done!"
echo "========================================="
echo "Image: $IMAGE_NAME"

if [ "$PUSH" = false ]; then
    echo ""
    echo "To push this image to ECR, run:"
    echo "  $0 --push --tag $TAG"
fi
