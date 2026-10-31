"""Compiler and linker flags shared by libkineto and its tests."""

load("//:libkineto/libkineto_defs.bzl", "KINETO_COMPILER_FLAGS")

# libkineto requires C++20 (CXX_STANDARD 20), and MSVC needs /utf-8 (the
# KINETO_COMPILE_OPTIONS of libkineto/CMakeLists.txt). KINETO_COMPILER_FLAGS
# are GCC/Clang flags.
KINETO_COPTS = select({
    Label("@rules_cc//cc/compiler:clang-cl"): [
        "/std:c++20",
        "/utf-8",
    ],
    Label("@rules_cc//cc/compiler:msvc-cl"): [
        "/std:c++20",
        "/utf-8",
    ],
    "//conditions:default": ["-std=c++20"] + KINETO_COMPILER_FLAGS,
})

# libkineto uses POSIX threads, which glibc before 2.34 provides separately.
KINETO_LINKOPTS = select({
    Label("@platforms//os:linux"): ["-lpthread"],
    "//conditions:default": [],
})
