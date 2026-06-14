#!/usr/bin/env bash
#
# ecr-login.sh — authenticate the local Docker client to the project's
# Amazon ECR registry using the credentials from `aws configure`.
#
# Usage:
#   ./scripts/ecr-login.sh
#
# Environment overrides:
#   AWS_REGION   AWS region of the registry      (default: eu-central-1)
#   AWS_PROFILE  AWS CLI profile to use           (default: the CLI default)
#   ACCOUNT_ID   AWS account ID owning the registry (default: looked up via STS)
#
set -euo pipefail

AWS_REGION="${AWS_REGION:-eu-central-1}"

# Resolve the account ID from the active credentials unless one was provided.
if [[ -z "${ACCOUNT_ID:-}" ]]; then
  ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
fi

REGISTRY="${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

echo "Authenticating Docker to ${REGISTRY} ..."

aws ecr get-login-password --region "${AWS_REGION}" \
  | docker login --username AWS --password-stdin "${REGISTRY}"

echo "Docker is now logged in to ${REGISTRY}"
