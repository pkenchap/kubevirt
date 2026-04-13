# ppc64le Cross-Compilation Setup for KubeVirt

## Overview

This document describes the setup for building KubeVirt binaries and images for ppc64le architecture using cross-compilation on x86_64 machines with Bazel.

## Current Status (2025)

### ✅ Completed: Binary Cross-Compilation Setup

The repository is configured to cross-compile ppc64le binaries on x86_64 build hosts, following the same pattern used for s390x in upstream kubevirt/kubevirt.

### Key Components Configured

1. **Cross-Compiler Toolchain**
   - Location: `hack/builder/Dockerfile.cross-compile`
   - Package: `gcc-powerpc64le-linux-gnu` (GCC 12.1.1)
   - Builder image: `quay.io/kubevirt/builder-cross:2604090246-9a1f806a7a`

2. **Bazel Platform Definition**
   - File: `bazel/platforms/BUILD`
   - Platform: `ppc64le-none-linux-gnu`
   - Constraints: `@platforms//cpu:ppc64le`, `@platforms//os:linux`

3. **C++ Toolchains**
   - Location: `bazel/toolchain/ppc64le-none-linux-gnu/`
   - CS9 toolchain: `ppc64le_linux_toolchain`
   - CS10 toolchain: `ppc64le_linux_toolchain_cs10`
   - **Critical**: `exec_compatible_with = @platforms//cpu:x86_64` (for cross-compilation)

4. **Build Configuration**
   - File: `.bazelrc`
   - Config: `crossbuild-ppc64le`
   - Flags: `--incompatible_enable_cc_toolchain_resolution --platforms=//bazel/platforms:ppc64le-none-linux-gnu`

5. **RPM Dependencies**
   - File: `rpm/BUILD.bazel`
   - CS9 and CS10 RPM targets for ppc64le
   - Aliases using `centos_stream_alias` macro

6. **Config Settings**
   - File: `rpm/centos_stream.bzl`
   - Platform config: `linux_ppc64le` (uses `@platforms//cpu:ppc64le`)
   - Compound settings: `ppc64le_cs9`, `ppc64le_cs10`

7. **Library Targets**
   - File: `BUILD.bazel`
   - `libvirt-libs`: Updated with ppc64le support
   - `libnbd-libs`: Updated with ppc64le support
   - Uses config_setting_group approach (not Go platform selectors)
   - `strip_include_prefix`: Absolute paths with leading/trailing slashes

## Building ppc64le Binaries

### Prerequisites

1. Build the cross-compilation builder image:
   ```bash
   cd hack/builder
   ./build.sh
   ```

2. Set the builder image:
   ```bash
   export KUBEVIRT_BUILDER_IMAGE="quay.io/kubevirt/builder-cross:2604090246-9a1f806a7a"
   ```

### Build Commands

**Build all binaries:**
```bash
BUILD_ARCH=crossbuild-ppc64le make bazel-build
```

**Build specific target:**
```bash
BUILD_ARCH=crossbuild-ppc64le bazel build //cmd/virt-launcher:virt-launcher
```

**Build with CS10:**
```bash
BUILD_ARCH=crossbuild-ppc64le bazel build --define=centos_stream_version=10 //cmd/virt-launcher:virt-launcher
```

## Alignment with Upstream

### Matches Upstream Pattern

- ✅ Config setting approach (not Go platform selectors in strip_include_prefix)
- ✅ Absolute paths with leading/trailing slashes in strip_include_prefix
- ✅ config_setting_group for platform + CentOS Stream version combinations
- ✅ centos_stream_alias for version selection
- ✅ Toolchain registration in `bazel/toolchain/toolchain.bzl`
- ✅ bazeldnf_dependencies() call in WORKSPACE

### ppc64le-Specific Additions

All ppc64le additions follow the exact same pattern as s390x in upstream:
- Platform definitions
- Toolchain configurations
- RPM targets
- Config settings
- Library select() statements

## Future Work: Container Images

### Missing Components for Image Building

To build complete ppc64le container images, the following base images need to be added to WORKSPACE:

1. **Distroless Go Base Images**
   ```starlark
   oci_pull(
       name = "go_image_base_ppc64le",
       digest = "sha256:...",  # Need ppc64le digest
       image = "gcr.io/distroless/base",
   )
   ```

2. **Alpine Images**
   ```starlark
   http_file(
       name = "alpine_image_ppc64le",
       sha256 = "...",
       urls = ["https://dl-cdn.alpinelinux.org/alpine/v3.x/releases/ppc64le/alpine-minirootfs-3.x.x-ppc64le.tar.gz"],
   )
   ```

3. **Fedora Test Tooling Images**
   - `@fedora_with_test_tooling_ppc64le`
   - `@alpine_with_test_tooling_ppc64le`

### BUILD Files to Update

Add ppc64le to select() statements in:
- `BUILD.bazel`: `passwd-image` base selection
- `containerimages/BUILD.bazel`: Alpine image selections
- `images/BUILD.bazel`: Test image selections
- `cmd/virt-launcher/BUILD.bazel`: Launcher base image
- `cmd/virt-handler/BUILD.bazel`: Handler base image
- `cmd/virt-exportserver/BUILD.bazel`: Export server base image
- `cmd/sidecars/BUILD.bazel`: Sidecar shim
- `cmd/libguestfs/BUILD.bazel`: Appliance layer

### Reference: 2020 ppc64le Support

KubeVirt had ppc64le support around 2020. You can reference that version for:
- Base image selections and digests
- Complete list of oci_image targets needing ppc64le
- Any architecture-specific configurations

## Troubleshooting

### Common Issues

1. **Toolchain Resolution Failure**
   - Check `exec_compatible_with` is set to `x86_64` (not `ppc`)
   - Verify platform constraints use `@platforms//cpu:ppc64le` (not `ppc`)

2. **Header Path Mismatch**
   - Ensure `strip_include_prefix` uses absolute paths: `/rpm/libvirt-libs_ppc64le_cs9/usr/include/`
   - Must include leading slash and trailing slash

3. **RPM Target Not Found**
   - Verify tar2files targets exist for both CS9 and CS10
   - Check centos_stream_alias is defined

4. **Missing bazeldnf_dependencies**
   - Ensure `bazeldnf_dependencies()` is called in WORKSPACE after gazelle_dependencies

## Testing

### Verify Toolchain Selection

```bash
BUILD_ARCH=crossbuild-ppc64le bazel cquery --output=starlark --starlark:expr="target.label" //cmd/virt-launcher:virt-launcher
```

### Check Platform Configuration

```bash
BUILD_ARCH=crossbuild-ppc64le bazel config
```

### Verify Binary Architecture

After building:
```bash
file bazel-bin/cmd/virt-launcher/virt-launcher_/virt-launcher
# Should show: ELF 64-bit LSB executable, 64-bit PowerPC or cisco 7500
```

## References

- Upstream KubeVirt: https://github.com/kubevirt/kubevirt
- s390x cross-compilation (reference pattern)
- Bazel C++ toolchain documentation
- CentOS Stream 9/10 RPM repositories for ppc64le