#!/usr/bin/env bash
#
# build-and-push.sh — build all eight Spring Petclinic microservice images for
# ARM64 (Graviton) and push them to the project's ECR repositories.
#
# Image creation does NOT use Maven's buildDocker profile. Instead:
#   1. Maven builds the service JARs.
#   2. `docker buildx build --platform linux/arm64` builds each image from the
#      shared docker/Dockerfile (FROM eclipse-temurin:17), then pushes it.
#
# Usage:
#   ./scripts/build-and-push.sh [TAG]
#
# Arguments:
#   TAG          Image tag to apply and push (default: latest)
#
# Environment overrides:
#   SOURCE_DIR   Path to the spring-petclinic-microservices checkout
#                                          (default: ../spring-petclinic-microservices)
#   AWS_REGION   AWS region of the registry (default: eu-central-1)
#   AWS_PROFILE  AWS CLI profile to use      (default: the CLI default)
#   ACCOUNT_ID   AWS account ID owning the registry (default: looked up via STS)
#   ENVIRONMENT  Repository environment prefix segment (default: dev)
#   SKIP_MAVEN   If set to "true", reuse existing target/*.jar and skip the build
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

TAG="${1:-latest}"
AWS_REGION="${AWS_REGION:-eu-central-1}"
ENVIRONMENT="${ENVIRONMENT:-dev}"
SOURCE_DIR="${SOURCE_DIR:-${REPO_ROOT}/../spring-petclinic-microservices}"
DOCKERFILE="${REPO_ROOT}/docker/Dockerfile"
PLATFORM="linux/arm64"

# The eight services; the Maven module directory is spring-petclinic-<service>.
SERVICES=(
  config-server
  discovery-server
  api-gateway
  customers-service
  visits-service
  vets-service
  genai-service
  admin-server
)

# --- Preconditions ---------------------------------------------------------
command -v docker >/dev/null || { echo "ERROR: docker not found" >&2; exit 1; }
docker buildx version >/dev/null 2>&1 || { echo "ERROR: docker buildx not available" >&2; exit 1; }

if [[ ! -d "${SOURCE_DIR}" ]]; then
  echo "ERROR: SOURCE_DIR '${SOURCE_DIR}' not found." >&2
  echo "       Set SOURCE_DIR to your spring-petclinic-microservices checkout." >&2
  exit 1
fi

if [[ -z "${ACCOUNT_ID:-}" ]]; then
  ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
fi
REGISTRY="${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

# --- Authenticate Docker to ECR -------------------------------------------
echo "==> Logging in to ${REGISTRY}"
aws ecr get-login-password --region "${AWS_REGION}" \
  | docker login --username AWS --password-stdin "${REGISTRY}"

# --- Build the JARs with Maven --------------------------------------------
if [[ "${SKIP_MAVEN:-}" != "true" ]]; then
  echo "==> Building JARs with Maven (skipping tests)"
  MVN="./mvnw"
  [[ -x "${SOURCE_DIR}/mvnw" ]] || MVN="mvn"
  ( cd "${SOURCE_DIR}" && "${MVN}" -q clean package -DskipTests )
else
  echo "==> SKIP_MAVEN=true — reusing existing JARs"
fi

# Ensure a buildx builder exists for cross-platform builds.
docker buildx inspect petclinic-builder >/dev/null 2>&1 \
  || docker buildx create --name petclinic-builder --use >/dev/null
docker buildx use petclinic-builder

# --- Build and push each ARM64 image --------------------------------------
for svc in "${SERVICES[@]}"; do
  module="spring-petclinic-${svc}"
  module_dir="${SOURCE_DIR}/${module}"

  if [[ ! -d "${module_dir}" ]]; then
    echo "ERROR: module directory '${module_dir}' not found" >&2
    exit 1
  fi

  # Locate the runnable JAR (exclude *-sources / *-javadoc / *.original).
  jar_path="$(find "${module_dir}/target" -maxdepth 1 -type f -name '*.jar' \
    ! -name '*-sources.jar' ! -name '*-javadoc.jar' ! -name '*.original' \
    | head -1)"

  if [[ -z "${jar_path}" ]]; then
    echo "ERROR: no JAR found in ${module_dir}/target — did the Maven build run?" >&2
    exit 1
  fi

  jar_rel="${jar_path#${SOURCE_DIR}/}"
  image="${REGISTRY}/petclinic-${ENVIRONMENT}/${svc}:${TAG}"

  echo "==> Building ${image} (${PLATFORM}) from ${jar_rel}"
  docker buildx build \
    --platform "${PLATFORM}" \
    --file "${DOCKERFILE}" \
    --build-arg "JAR_FILE=${jar_rel}" \
    --tag "${image}" \
    --push \
    "${SOURCE_DIR}"
done

echo "==> Done. Pushed ${#SERVICES[@]} ARM64 images to ${REGISTRY}/petclinic-${ENVIRONMENT}/"
