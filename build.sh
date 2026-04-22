#!/bin/bash

set -e

IMAGE_NAME="aws-vpn-client-saml"
TAG="latest"
REGISTRY="${REGISTRY:-docker.io/yourusername}"  # ⚠️ Change to your registry

echo "Building AWS VPN Client Docker image..."
docker build -t ${REGISTRY}/${IMAGE_NAME}:${TAG} .

if [ "$1" == "--push" ]; then
    echo "Pushing to registry..."
    docker push ${REGISTRY}/${IMAGE_NAME}:${TAG}
fi

echo "Done! Image: ${REGISTRY}/${IMAGE_NAME}:${TAG}"
