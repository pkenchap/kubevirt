# ppc64le Image Building Configuration - Complete Setup

## Overview

This document describes the complete ppc64le image building configuration that has been added to the KubeVirt repository, following the s390x pattern from upstream.

## WORKSPACE Changes - Base Images Added

### 1. Distroless Go Base Image ✅
```starlark
oci_pull(
    name = "go_image_base_ppc64le",
    digest = "sha256:0e72bb83ef5a42644da031c5b11b97e1c9d74ed4322a5314a88db97fbacbc9d3",
    image = "gcr.io/distroless/base-debian12",
)
```
**Status:** Real digest configured

### 2. Alpine Base Image ✅
```starlark
http_file(
    name = "alpine_image_ppc64le",
    sha256 = "f0ee46531aa7b897afa804b8fcc4a94e73143b4ce1a614e5c6a25b27a538d920",
    urls = [
        "https://dl-cdn.alpinelinux.org/alpine/v3.18/releases/ppc64le/alpine-standard-3.18.8-ppc64le.iso",
    ],
)
```
**Status:** Real SHA256 configured (Alpine 3.18.8)

### 3. Test Tooling Images ⚠️
```starlark
oci_pull(
    name = "alpine_with_test_tooling_ppc64le",
    digest = "PLACEHOLDER_ALPINE_DIGEST",
    image = "quay.io/kubevirtci/alpine-with-test-tooling-container-disk",
)

oci_pull(
    name = "fedora_with_test_tooling_ppc64le",
    digest = "PLACEHOLDER_FEDORA_DIGEST",
    image = "quay.io/kubevirtci/fedora-with-test-tooling",
)
```
**Status:** Placeholders - Need real digests

## How to Get Real Digests for Placeholders

### Method 1: Using docker buildx imagetools (Recommended)

```bash
# Get Fedora test tooling digest for ppc64le
docker buildx imagetools inspect quay.io/kubevirtci/fedora-with-test-tooling | grep -A2 ppc64le

# Get Alpine test tooling digest for ppc64le
docker buildx imagetools inspect quay.io/kubevirtci/alpine-with-test-tooling-container-disk | grep -A2 ppc64le
```

### Method 2: Using skopeo

```bash
# Get Fedora test tooling digest
skopeo inspect --raw docker://quay.io/kubevirtci/fedora-with-test-tooling | jq -r '.manifests[] | select(.platform.architecture=="ppc64le") | .digest'

# Get Alpine test tooling digest
skopeo inspect --raw docker://quay.io/kubevirtci/alpine-with-test-tooling-container-disk | jq -r '.manifests[] | select(.platform.architecture=="ppc64le") | .digest'
```

### Method 3: Using crane

```bash
# Get Fedora test tooling digest
crane manifest quay.io/kubevirtci/fedora-with-test-tooling | jq -r '.manifests[] | select(.platform.architecture=="ppc64le") | .digest'

# Get Alpine test tooling digest
crane manifest quay.io/kubevirtci/alpine-with-test-tooling-container-disk | jq -r '.manifests[] | select(.platform.architecture=="ppc64le") | .digest'
```

### Updating WORKSPACE with Real Digests

Once you have the digests, update WORKSPACE:

```bash
# Replace PLACEHOLDER_FEDORA_DIGEST
sed -i 's/PLACEHOLDER_FEDORA_DIGEST/sha256:actual_fedora_digest_here/' WORKSPACE

# Replace PLACEHOLDER_ALPINE_DIGEST
sed -i 's/PLACEHOLDER_ALPINE_DIGEST/sha256:actual_alpine_digest_here/' WORKSPACE
```

## BUILD Files Updated with ppc64le Support

### 1. Root BUILD.bazel
**Changes:**
- `passwd-image`: Added `@io_bazel_rules_go//go/platform:linux_ppc64le` → `@go_image_base_ppc64le`

### 2. containerimages/BUILD.bazel
**Changes:**
- Alpine image selection: Added ppc64le case
- Architecture string selection: Added ppc64le → "ppc64le"
- Test tooling images: Added ppc64le selections

### 3. images/BUILD.bazel
**Changes:**
- Architecture selection: Added ppc64le → "ppc64le"
- Test image tars: Added `//rpm:testimage_ppc64le`

### 4. images/disks-images-provider/BUILD.bazel
**Changes:**
- Alpine image selection: Added ppc64le case
- Image copy command: Added ppc64le-specific command

### 5. cmd/virt-launcher/BUILD.bazel
**Changes:**
- Base image selection: Added `@go_image_base_ppc64le`
- Launcher tars: Added `//rpm:launcherbase_ppc64le`

### 6. cmd/virt-handler/BUILD.bazel
**Changes:**
- Base image selection: Added `@go_image_base_ppc64le`
- Handler tars: Added `//rpm:handlerbase_ppc64le`
- Passt repair: Added `passt_repair_for_arch("ppc64le")`

### 7. cmd/virt-exportserver/BUILD.bazel
**Changes:**
- Base image selection: Added `@go_image_base_ppc64le`
- Export server tars: Added ppc64le-specific layers

### 8. cmd/sidecars/BUILD.bazel
**Changes:**
- Sidecar shim tars: Added `//rpm:sidecar-shim_ppc64le`

### 9. cmd/libguestfs/BUILD.bazel
**Changes:**
- Appliance layer: Added `appliance_layer_ppc64le`

## Building Process

### Step 1: Binary Cross-Compilation (Works Now)

```bash
export KUBEVIRT_BUILDER_IMAGE="quay.io/kubevirt/builder-cross:2604090246-9a1f806a7a"
BUILD_ARCH=crossbuild-ppc64le make bazel-build
```

This will build all ppc64le binaries using cross-compilation.

### Step 2: Container Image Building (After Fixing Placeholders)

Once you've replaced the placeholder digests:

```bash
export KUBEVIRT_BUILDER_IMAGE="quay.io/kubevirt/builder-cross:2604090246-9a1f806a7a"
BUILD_ARCH=crossbuild-ppc64le make bazel-push-images
```

This will build and push all ppc64le container images.

## Verification

### Check Binary Architecture
```bash
file bazel-bin/cmd/virt-launcher/virt-launcher_/virt-launcher
# Expected: ELF 64-bit LSB executable, 64-bit PowerPC or cisco 7500
```

### Check Container Image Architecture
```bash
docker buildx imagetools inspect <your-registry>/virt-launcher:latest
# Should show ppc64le in the manifest list
```

## Summary of ppc64le Support

### ✅ Fully Configured
1. Cross-compilation toolchain (GCC 12.1.1)
2. Bazel platform definitions
3. C++ toolchains (CS9 and CS10)
4. RPM dependencies (CS9 and CS10)
5. Config settings and aliases
6. Library targets (libvirt-libs, libnbd-libs)
7. Base container images (go_image_base, alpine_image)
8. All BUILD file select() statements

### ⚠️ Needs Real Digests
1. `fedora_with_test_tooling_ppc64le` - PLACEHOLDER_FEDORA_DIGEST
2. `alpine_with_test_tooling_ppc64le` - PLACEHOLDER_ALPINE_DIGEST

### 📋 Pattern Followed
All ppc64le additions follow the exact same pattern as s390x in upstream kubevirt/kubevirt:
- Same select() structure
- Same naming conventions
- Same RPM target patterns
- Same image layering approach

## Troubleshooting

### Issue: Placeholder digest error during build
**Solution:** Replace placeholders with real digests using methods above

### Issue: Image not found for ppc64le
**Solution:** Verify the image exists for ppc64le architecture:
```bash
docker buildx imagetools inspect <image-name>
```

### Issue: Wrong architecture in final image
**Solution:** Verify platform flag is set correctly:
```bash
BUILD_ARCH=crossbuild-ppc64le bazel build --platforms=//bazel/platforms:ppc64le-none-linux-gnu <target>
```

## Next Steps

1. **Get real digests** for placeholder images
2. **Update WORKSPACE** with real digests
3. **Test binary build** (should work now)
4. **Test image build** (after fixing placeholders)
5. **Push images** to your registry
6. **Deploy and test** on ppc64le hardware

## Reference

- Upstream KubeVirt: https://github.com/kubevirt/kubevirt
- s390x pattern (reference for ppc64le)
- 2020 KubeVirt version with ppc64le support
- Alpine Linux ppc64le releases: https://alpinelinux.org/downloads/
- Distroless base images: https://github.com/GoogleContainerTools/distroless