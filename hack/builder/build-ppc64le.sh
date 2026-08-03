#!/usr/bin/env bash
# Build a native ppc64le builder image.
# Must be run on a ppc64le host (CentOS Stream 10).
# Requires a pre-built Bazel binary at hack/builder/bazel-ppc64le.
set -ex

source "$(dirname "$0")/../common.sh"

BAZEL_VERSION=7.5.0

fail_if_cri_bin_missing

SCRIPT_DIR="$(
    cd "$(dirname "${BASH_SOURCE[0]}")"
    pwd
)"

# This script is ppc64le-native only
if [ "$(uname -m)" != "ppc64le" ]; then
    echo >&2 "ERROR: This script must be run on a ppc64le host."
    echo >&2 "       Current host arch: $(uname -m)"
    exit 1
fi

# shellcheck source=hack/builder/common.sh
. "${SCRIPT_DIR}/common.sh"
# shellcheck source=hack/builder/version.sh
. "${SCRIPT_DIR}/version.sh"

BAZEL_BINARY="${SCRIPT_DIR}/bazel-ppc64le"

# The Bazel binary for ppc64le must be built from source on the host.
# See: https://github.com/bazelbuild/bazel/releases (no pre-built binary for ppc64le)
if [ ! -f "${BAZEL_BINARY}" ]; then
    echo >&2 "ERROR: Bazel binary not found at ${BAZEL_BINARY}"
    echo >&2 ""
    echo >&2 "Build it on this ppc64le host with:"
    echo >&2 "  wget https://github.com/bazelbuild/bazel/releases/download/${BAZEL_VERSION}/bazel-${BAZEL_VERSION}-dist.zip"
    echo >&2 "  unzip bazel-${BAZEL_VERSION}-dist.zip -d bazel-src && cd bazel-src"
    echo >&2 "  env EXTRA_BAZEL_ARGS=\"--tool_java_runtime_version=local_jdk\" bash ./compile.sh"
    echo >&2 "  cp output/bazel ${BAZEL_BINARY}"
    exit 1
fi

echo >&2 "Using Bazel binary: ${BAZEL_BINARY} ($(file "${BAZEL_BINARY}" | grep -o 'ELF.*'))"

IMAGE_TAG="${DOCKER_PREFIX}/builder-ppc64le:${VERSION}"

${KUBEVIRT_CRI} >&2 build \
    --platform="linux/ppc64le" \
    -t "${IMAGE_TAG}" \
    --build-arg SONOBUOY_ARCH=ppc64le \
    -f "${SCRIPT_DIR}/Dockerfile.ppc64le" \
    "${SCRIPT_DIR}"

echo >&2 "Successfully built: ${IMAGE_TAG}"

# Print the version for use by other callers such as publish scripts
echo "${VERSION}"
