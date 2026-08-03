load("@bazeldnf//bazeldnf:toolchain.bzl", "bazeldnf_toolchain")

# Cross-compile toolchain: exec on x86_64, target ppc64le
# (kept for cross-build compatibility, though unused since bazeldnf_prebuilt handles this)
bazeldnf_toolchain(
    name = "bazeldnf_ppc64le_toolchain_impl",
    tool = "@bazeldnf//:bazeldnf",
)

toolchain(
    name = "bazeldnf_ppc64le_toolchain",
    exec_compatible_with = [
        "@platforms//os:linux",
        "@platforms//cpu:x86_64",
    ],
    target_compatible_with = [
        "@platforms//os:linux",
        "@platforms//cpu:ppc64le",
    ],
    toolchain = ":bazeldnf_ppc64le_toolchain_impl",
    toolchain_type = "@bazeldnf//bazeldnf:toolchain_type",
)

# Native ppc64le toolchain: exec AND target on ppc64le.
# Workaround for upstream bazeldnf bug: linux-ppc64le mapped to @platforms//cpu:ppc
# instead of @platforms//cpu:ppc64le, so the prebuilt toolchain never matches.
bazeldnf_toolchain(
    name = "bazeldnf_ppc64le_native_toolchain_impl",
    tool = "@bazeldnf_linux_ppc64le_binary//file",
)

toolchain(
    name = "bazeldnf_ppc64le_native_toolchain",
    exec_compatible_with = [
        "@platforms//os:linux",
        "@platforms//cpu:ppc64le",
    ],
    target_compatible_with = [
        "@platforms//os:linux",
        "@platforms//cpu:ppc64le",
    ],
    toolchain = ":bazeldnf_ppc64le_native_toolchain_impl",
    toolchain_type = "@bazeldnf//bazeldnf:toolchain_type",
)
