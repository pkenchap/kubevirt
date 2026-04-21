# Building KubeVirt ppc64le Images via Cross-Compilation

This guide documents the complete process to build KubeVirt container images for ppc64le architecture using cross-compilation on an x86_64 machine.

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Environment Setup](#environment-setup)
3. [Code Changes Required](#code-changes-required)
4. [Building Images](#building-images)
5. [Pushing to Registry](#pushing-to-registry)
6. [Deployment](#deployment)
7. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Hardware & OS
- **Build Machine**: x86_64 Linux system (RHEL/CentOS/Fedora)
- **Target Machine**: ppc64le system with OpenShift/Kubernetes
- **Minimum RAM**: 16GB (32GB recommended)
- **Disk Space**: 50GB free

### Software Requirements
```bash
# Install required packages
sudo dnf install -y \
    git \
    golang \
    podman \
    skopeo \
    make \
    gcc \
    gcc-c++ \
    python3 \
    python3-pip

# Install bazeldnf (required for RPM tree generation)
wget https://github.com/rmohr/bazeldnf/releases/download/v0.5.9/bazeldnf-v0.5.9-linux-amd64
sudo install bazeldnf-v0.5.9-linux-amd64 /usr/local/bin/bazeldnf
```

### Container Registry
```bash
# Start local registry for intermediate storage
podman run -d -p 5000:5000 --restart=always --name registry registry:2

# Verify registry is running
curl http://localhost:5000/v2/
# Should return: {}
```

---

## Environment Setup

### 1. Clone KubeVirt Repository
```bash
git clone https://github.com/kubevirt/kubevirt.git
cd kubevirt
```

### 2. Set Environment Variables
```bash
# Builder image with cross-compilation support
export KUBEVIRT_BUILDER_IMAGE="quay.io/kubevirt/builder-cross:2604090246-9a1f806a7a"

# Local registry for intermediate storage
export DOCKER_PREFIX=localhost:5000
export DOCKER_TAG=v1.0.0-ppc64le

# Build architecture
export BUILD_ARCH=crossbuild-ppc64le
```

---

## Code Changes Required

### 1. Add libvirt Packages to launcherbase

**File**: `rpm/BUILD.bazel`

**Location**: Find the `launcherbase_ppc64le_cs10` rpmtree definition (around line 3532)

**Add these packages** after the existing libvirt-libs entry:
```bazel
"@libvirt-client-0__11.10.0-12.el10.ppc64le//rpm",
"@libvirt-daemon-common-0__11.10.0-12.el10.ppc64le//rpm",
"@libvirt-daemon-driver-qemu-0__11.10.0-1.virt.el10.ppc64le//rpm",
"@libvirt-daemon-log-0__11.10.0-12.el10.ppc64le//rpm",
"@libvirt-libs-0__11.10.0-12.el10.ppc64le//rpm",
```

### 2. Create RPM Generation Script

**File**: `generate-ppc64le-rpms-cs10.sh`

Create this script in the repository root:

```bash
#!/usr/bin/env bash
#
# Generate all ppc64le RPM definitions for CentOS Stream 10
# This script uses bazeldnf to create deterministic RPM trees with SHA256 hashes
#

set -e

ARCH="ppc64le"
REPOFILE="rpm/repo-cs10.yaml"
BASESYSTEM="centos-stream-release"
BUILDFILE="rpm/BUILD.bazel"

echo "=========================================="
echo "Generating ppc64le RPM definitions for CS10"
echo "=========================================="

# Clear cache to ensure fresh metadata
echo "Clearing bazeldnf cache..."
rm -rf ~/.cache/bazeldnf

# Fetch all repo metadata
echo "Fetching repository metadata..."
/usr/local/bin/bazeldnf fetch --repofile "${REPOFILE}"

echo ""
echo "=========================================="
echo "Generating RPM trees..."
echo "=========================================="

# Function to generate rpmtree
generate_rpmtree() {
    local name=$1
    shift
    local packages=("$@")
    
    echo ""
    echo "=== Generating ${name} ==="
    /usr/local/bin/bazeldnf rpmtree \
        --arch "${ARCH}" \
        --basesystem "${BASESYSTEM}" \
        --repofile "${REPOFILE}" \
        --buildfile "${BUILDFILE}" \
        --name "${name}" \
        --public \
        "${packages[@]}" || {
        echo "ERROR: Failed to generate ${name}"
        return 1
    }
    echo "✓ ${name} generated successfully"
}

# 1. testimage_ppc64le_cs10
echo "1/11: testimage_ppc64le_cs10"
generate_rpmtree "testimage_ppc64le_cs10" \
    coreutils \
    cpio \
    diffutils \
    findutils \
    gawk \
    gcc \
    glibc-static \
    grep \
    gzip \
    iproute \
    iputils \
    make \
    nftables \
    procps-ng \
    qemu-img \
    sed \
    tar

# 2. libvirt-devel_ppc64le_cs10
echo "2/11: libvirt-devel_ppc64le_cs10"
generate_rpmtree "libvirt-devel_ppc64le_cs10" \
    libvirt-devel \
    lz4-libs

# 3. libnbd-devel_ppc64le_cs10
echo "3/11: libnbd-devel_ppc64le_cs10"
generate_rpmtree "libnbd-devel_ppc64le_cs10" \
    libnbd-devel

# 4. sandboxroot_ppc64le_cs10
echo "4/11: sandboxroot_ppc64le_cs10"
generate_rpmtree "sandboxroot_ppc64le_cs10" \
    libvirt-devel \
    libnbd-devel

# 5. launcherbase_ppc64le_cs10
echo "5/11: launcherbase_ppc64le_cs10"
generate_rpmtree "launcherbase_ppc64le_cs10" \
    acl \
    findutils \
    gawk \
    glibc-minimal-langpack \
    iproute \
    iptables-nft \
    libvirt-client \
    libvirt-daemon-common \
    libvirt-daemon-driver-qemu \
    libvirt-daemon-log \
    libvirt-libs \
    nftables \
    passt \
    procps-ng \
    qemu-img \
    qemu-kvm-core \
    selinux-policy \
    selinux-policy-targeted \
    shadow-utils \
    tar \
    util-linux \
    vim-minimal

# 6. passt_tree_ppc64le_cs10
echo "6/11: passt_tree_ppc64le_cs10"
generate_rpmtree "passt_tree_ppc64le_cs10" \
    passt

# 7. handlerbase_ppc64le_cs10
echo "7/11: handlerbase_ppc64le_cs10"
generate_rpmtree "handlerbase_ppc64le_cs10" \
    acl \
    findutils \
    gawk \
    glibc-minimal-langpack \
    iproute \
    nftables \
    passt \
    procps-ng \
    qemu-img \
    selinux-policy-targeted \
    shadow-utils \
    tar \
    util-linux \
    vim-minimal \
    xorriso

# 8. exportserverbase_ppc64le_cs10
echo "8/11: exportserverbase_ppc64le_cs10"
generate_rpmtree "exportserverbase_ppc64le_cs10" \
    nbdkit \
    nbdkit-curl-plugin \
    qemu-img

# 9. libguestfs-tools_ppc64le_cs10
echo "9/11: libguestfs-tools_ppc64le_cs10"
generate_rpmtree "libguestfs-tools_ppc64le_cs10" \
    libguestfs

# 10. pr-helper_ppc64le_cs10
echo "10/11: pr-helper_ppc64le_cs10"
generate_rpmtree "pr-helper_ppc64le_cs10" \
    qemu-pr-helper

# 11. sidecar-shim_ppc64le_cs10
echo "11/11: sidecar-shim_ppc64le_cs10"
generate_rpmtree "sidecar-shim_ppc64le_cs10" \
    passt

echo ""
echo "=========================================="
echo "✓ All ppc64le RPM trees generated successfully!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Review the generated entries in rpm/BUILD.bazel"
echo "2. Commit the changes: git add rpm/BUILD.bazel rpm/repo-cs10.yaml"
echo "3. Build with: BUILD_ARCH=crossbuild-ppc64le make bazel-build-images"
```

Make the script executable:
```bash
chmod +x generate-ppc64le-rpms-cs10.sh
```

### 3. Regenerate RPM Trees

Run the script to generate all RPM tree definitions:
```bash
./generate-ppc64le-rpms-cs10.sh
```

**Expected output:**
```
✓ All ppc64le RPM trees generated successfully!
```

This will update `rpm/BUILD.bazel` with all required package definitions including lz4-libs dependency.

---

## Building Images

### 1. Clean Build (Optional but Recommended)
```bash
bazel clean
```

### 2. Build All Images
```bash
BUILD_ARCH=crossbuild-ppc64le make bazel-build-images
```

**Build time**: ~90-120 seconds on modern hardware

**Expected output:**
```
INFO: Build completed successfully, 41 total actions
```

### 3. Verify Build Artifacts
```bash
# List built images
bazel cquery --config=crossbuild-ppc64le 'kind("oci_image", //...)' --output=label
```

---

## Pushing to Registry

### 1. Push to Local Registry
```bash
# Ensure local registry is running
podman ps | grep registry

# Push all images
BUILD_ARCH=crossbuild-ppc64le make bazel-push-images
```

**Expected output:**
```
✓ Successfully pushed: 30 images
```

### 2. Verify Images in Local Registry
```bash
curl http://localhost:5000/v2/_catalog
```

Should show all 30 images including:
- virt-operator
- virt-api
- virt-controller
- virt-handler
- virt-launcher
- virt-exportproxy
- virt-exportserver
- And 23 supporting images

### 3. Copy to Quay.io (or your registry)

**Login to Quay.io:**
```bash
podman login quay.io
# Enter username and password
```

**Copy all images:**
```bash
#!/bin/bash
# Script to copy all images to Quay.io

IMAGES=(
    "virt-operator"
    "virt-api"
    "virt-controller"
    "virt-handler"
    "virt-launcher"
    "virt-exportproxy"
    "virt-exportserver"
    "virt-synchronization-controller"
    "alpine-container-disk-demo"
    "alpine-with-test-tooling-container-disk"
    "fedora-with-test-tooling-container-disk"
    "vm-killer"
    "sidecar-shim"
    "disks-images-provider"
    "libguestfs-tools"
    "test-helpers"
    "conformance"
    "pr-helper"
    "example-hook-sidecar"
    "example-disk-mutation-hook-sidecar"
    "example-cloudinit-hook-sidecar"
    "cirros-custom-container-disk-demo"
    "cirros-container-disk-demo"
    "virtio-container-disk"
    "alpine-ext-kernel-boot-demo"
    "fedora-realtime-container-disk"
    "winrmcli"
    "network-slirp-binding"
    "network-passt-binding"
    "network-passt-binding-cni"
)

QUAY_ORG="your-quay-username"  # Change this!
TAG="v1.0.0-ppc64le"

for image in "${IMAGES[@]}"; do
    echo "Copying ${image}..."
    skopeo copy --src-tls-verify=false \
        docker://localhost:5000/${image}:${TAG} \
        docker://quay.io/${QUAY_ORG}/${image}:${TAG}
done

echo "✓ All images copied to Quay.io"
```

---

## Deployment

### 1. Prepare Deployment Manifest

Create `kubevirt-cr.yaml`:
```yaml
apiVersion: kubevirt.io/v1
kind: KubeVirt
metadata:
  name: kubevirt
  namespace: kubevirt
spec:
  imageRegistry: quay.io/your-quay-username
  imageTag: v1.0.0-ppc64le
  imagePullPolicy: Always
  workloadUpdateStrategy:
    workloadUpdateMethods:
    - LiveMigrate
  configuration:
    developerConfiguration:
      featureGates:
      - LiveMigration
```

### 2. Deploy on ppc64le Cluster

```bash
# On your ppc64le machine with kubectl/oc access

# Create namespace
kubectl create namespace kubevirt

# Deploy operator
kubectl apply -f https://github.com/kubevirt/kubevirt/releases/download/v1.8.2/kubevirt-operator.yaml

# Wait for operator
kubectl wait --for=condition=Available --timeout=300s \
    deployment/virt-operator -n kubevirt

# Deploy KubeVirt CR
kubectl apply -f kubevirt-cr.yaml

# Watch deployment
kubectl get pods -n kubevirt -w
```

### 3. Verify Deployment

```bash
# Check all pods are running
kubectl get pods -n kubevirt

# Expected output:
# NAME                               READY   STATUS    RESTARTS   AGE
# virt-api-xxxxx                     1/1     Running   0          2m
# virt-controller-xxxxx              1/1     Running   0          2m
# virt-handler-xxxxx                 1/1     Running   0          2m
# virt-operator-xxxxx                1/1     Running   0          3m

# Check virt-handler logs (should not have virtqemud errors)
kubectl logs -n kubevirt -l kubevirt.io=virt-handler

# Verify KubeVirt is ready
kubectl get kubevirt -n kubevirt
```

---

## Troubleshooting

### Issue: "virtqemud: command not found"

**Symptom**: virt-handler pods crash with error about missing virtqemud

**Solution**: Ensure libvirt packages are in launcherbase_ppc64le_cs10:
```bash
grep "libvirt-daemon-driver-qemu" rpm/BUILD.bazel
```

If missing, add the packages and regenerate RPM trees.

### Issue: "liblz4.so.1: cannot open shared object file"

**Symptom**: Build fails with missing lz4 library files

**Solution**: Ensure lz4-libs is explicitly included in libvirt-devel generation:
```bash
# Check generate-ppc64le-rpms-cs10.sh line 77-78
generate_rpmtree "libvirt-devel_ppc64le_cs10" \
    libvirt-devel \
    lz4-libs  # This line is critical!
```

### Issue: "connection refused" when pushing to localhost:5000

**Symptom**: Cannot push images to local registry

**Solution**: Start the registry container:
```bash
podman start registry
# or if it doesn't exist:
podman run -d -p 5000:5000 --restart=always --name registry registry:2
```

### Issue: Build takes too long or runs out of memory

**Solution**: 
```bash
# Limit Bazel memory usage
echo "build --local_ram_resources=8192" >> .bazelrc.local

# Build specific images instead of all
BUILD_ARCH=crossbuild-ppc64le make bazel-build-images WHAT=virt-launcher-image
```

### Issue: Images fail to pull on ppc64le cluster

**Solution**: 
1. Verify images exist on Quay.io:
   ```bash
   skopeo inspect docker://quay.io/your-username/virt-launcher:v1.0.0-ppc64le
   ```

2. Check image pull secrets:
   ```bash
   kubectl get secrets -n kubevirt
   ```

3. Make repositories public on Quay.io or create pull secret:
   ```bash
   kubectl create secret docker-registry quay-secret \
       --docker-server=quay.io \
       --docker-username=your-username \
       --docker-password=your-password \
       -n kubevirt
   ```

---

## Key Differences from Upstream

### 1. Additional libvirt Packages
Upstream s390x includes these packages, but ppc64le needed them added explicitly:
- libvirt-client
- libvirt-daemon-common
- libvirt-daemon-driver-qemu (contains virtqemud)
- libvirt-daemon-log
- libvirt-libs

### 2. Explicit lz4-libs Dependency
Bazeldnf's automatic dependency resolution didn't include lz4-libs for ppc64le, requiring explicit inclusion.

### 3. CentOS Stream 10 Only
ppc64le builds use only CS10 (no CS9 version exists for ppc64le).

---

## References

- [KubeVirt Documentation](https://kubevirt.io/user-guide/)
- [Bazel Cross-Compilation](https://bazel.build/configure/toolchains)
- [CentOS Stream 10 ppc64le Repository](https://mirror.stream.centos.org/10-stream/BaseOS/ppc64le/os/)
- [KubeVirt GitHub](https://github.com/kubevirt/kubevirt)

---

## Changelog

- **2026-04-21**: Initial documentation for ppc64le cross-compilation
- Added libvirt packages to launcherbase
- Fixed lz4-libs dependency issue
- Successfully built and deployed all 30 images

---

## Contributing

If you encounter issues or have improvements:
1. Test the changes thoroughly
2. Update this documentation
3. Submit a pull request to KubeVirt upstream

---

**Document Version**: 1.0  
**Last Updated**: 2026-04-21  
**Tested On**: RHEL 9.x (build), RHEL 10.1 ppc64le (deploy)