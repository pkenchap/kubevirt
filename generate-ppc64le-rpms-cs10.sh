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

# 5. launcherbase_ppc64le_cs10 - Complete package list (x86-specific packages removed, ppc64le additions included)
echo "5/11: launcherbase_ppc64le_cs10"
generate_rpmtree "launcherbase_ppc64le_cs10" \
    acl \
    alternatives \
    audit-libs \
    authselect \
    authselect-libs \
    basesystem \
    bash \
    bzip2 \
    bzip2-libs \
    ca-certificates \
    capstone \
    centos-gpg-keys \
    centos-stream-release \
    centos-stream-repos \
    coreutils-single \
    cracklib \
    cracklib-dicts \
    crypto-policies \
    curl \
    cyrus-sasl-gssapi \
    cyrus-sasl-lib \
    dbus \
    dbus-broker \
    dbus-common \
    diffutils \
    duktape \
    elfutils-libelf \
    expat \
    filesystem \
    findutils \
    gawk \
    gdbm \
    gdbm-libs \
    gettext \
    gettext-envsubst \
    gettext-libs \
    gettext-runtime \
    glib2 \
    glibc \
    glibc-common \
    glibc-minimal-langpack \
    gmp \
    gnutls \
    gnutls-dane \
    gnutls-utils \
    grep \
    gzip \
    iproute \
    iproute-tc \
    iptables-libs \
    jansson \
    json-c \
    json-glib \
    keyutils-libs \
    kmod \
    krb5-libs \
    libacl \
    libaio \
    libatomic \
    libattr \
    libblkid \
    libbpf \
    libburn \
    libcap \
    libcap-ng \
    libcbor \
    libcom_err \
    libcurl-minimal \
    libeconf \
    libevent \
    libfdisk \
    libfdt \
    libffi \
    libfido2 \
    libgcc \
    libgomp \
    libibverbs \
    libidn2 \
    libisoburn \
    libisofs \
    libmnl \
    libmount \
    libnbd \
    libnetfilter_conntrack \
    libnfnetlink \
    libnftnl \
    libnghttp2 \
    libnl3 \
    libpcap \
    libpng \
    libpwquality \
    libseccomp \
    libselinux \
    libselinux-utils \
    libsemanage \
    libsepol \
    libslirp \
    libsmartcols \
    libssh \
    libssh-config \
    libstdc++ \
    libtasn1 \
    libtirpc \
    libunistring \
    liburing \
    libusb1 \
    libutempter \
    libuuid \
    libverto \
    libxcrypt \
    libxml2 \
    libzstd \
    lz4-libs \
    lzo \
    lzop \
    mpfr \
    ncurses-base \
    ncurses-libs \
    nftables \
    nmap-ncat \
    numactl-libs \
    openssl-fips-provider \
    openssl-libs \
    p11-kit \
    p11-kit-trust \
    pam \
    pam-libs \
    passt \
    pcre2 \
    pcre2-syntax \
    pixman \
    policycoreutils \
    polkit \
    polkit-libs \
    popt \
    procps-ng \
    protobuf-c \
    psmisc \
    qemu-img \
    qemu-kvm \
    readline \
    sed \
    selinux-policy \
    selinux-policy-targeted \
    setup \
    shadow-utils \
    snappy \
    systemd \
    systemd-container \
    systemd-libs \
    systemd-pam \
    tar \
    unbound-libs \
    util-linux \
    util-linux-core \
    vim-data \
    vim-minimal \
    virtiofsd \
    xorriso \
    xz \
    xz-libs \
    zlib-ng-compat \
    zstd

# 6. passt_tree_ppc64le_cs10
echo "6/11: passt_tree_ppc64le_cs10"
generate_rpmtree "passt_tree_ppc64le_cs10" \
    passt

# 7. handlerbase_ppc64le_cs10
# Note: Using minimal package list - bazeldnf will resolve all dependencies
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
echo "3. Build with: KUBEVIRT_CENTOS_STREAM_VERSION=10 BUILD_ARCH=ppc64le make bazel-build-images"
