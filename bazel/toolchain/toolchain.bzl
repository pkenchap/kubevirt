def register_all_toolchains():
    native.register_toolchains(
        # Native ppc64le toolchain - must be registered first so it takes
        # priority over cross-compile toolchains on native ppc64le hosts
        "//bazel/toolchain/ppc64le-none-linux-gnu:ppc64le_linux_toolchain_native",
        # CS10 toolchains (cross-compile from x86_64)
        "//bazel/toolchain/x86_64-none-linux-gnu:x86_64_linux_toolchain_cs10",
        "//bazel/toolchain/aarch64-none-linux-gnu:aarch64_linux_toolchain_cs10",
        "//bazel/toolchain/s390x-none-linux-gnu:s390x_linux_toolchain_cs10",
        "//bazel/toolchain/ppc64le-none-linux-gnu:ppc64le_linux_toolchain_cs10",
        # Default toolchains (CS9, cross-compile from x86_64)
        "//bazel/toolchain/s390x-none-linux-gnu:s390x_linux_toolchain",
        "//bazel/toolchain/aarch64-none-linux-gnu:aarch64_linux_toolchain",
        "//bazel/toolchain/ppc64le-none-linux-gnu:ppc64le_linux_toolchain",
        "//bazel/toolchain/x86_64-none-linux-gnu:x86_64_linux_toolchain",
    )
