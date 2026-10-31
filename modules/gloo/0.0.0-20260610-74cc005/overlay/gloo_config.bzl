"""gloo/config.h's values, and the compiler flags shared by Gloo and its tests.

The select() keys are Label()s so that the test module (gloo/test/), which
loads this file as @gloo//:gloo_config.bzl, resolves them as @gloo does.
"""

# Gloo needs C++17 (its CMakeLists.txt sets CMAKE_CXX_STANDARD 20, but the
# sources use no C++20 feature).
GLOO_COPTS = select({
    Label("@rules_cc//cc/compiler:clang-cl"): ["/std:c++17"],
    Label("@rules_cc//cc/compiler:msvc-cl"): ["/std:c++17"],
    "//conditions:default": ["-std=c++17"],
})

# The headers include <winsock2.h> (gloo/common/win.h) and use std::min and
# std::max, so their users need NOMINMAX as well (gloo/CMakeLists.txt adds it
# with MSVC).
GLOO_DEFINES = select({
    Label("@platforms//os:windows"): ["NOMINMAX"],
    "//conditions:default": [],
})

_CONFIG = {
    "GLOO_HAVE_TRANSPORT_IBVERBS": False,
    "GLOO_HAVE_TRANSPORT_TCP_TLS": False,
    "GLOO_USE_AVX": False,
    "GLOO_USE_CUDA": False,
    "GLOO_USE_IBVERBS": False,
    "GLOO_USE_MPI": False,
    "GLOO_USE_NCCL": False,
    "GLOO_USE_RCCL": False,
    "GLOO_USE_REDIS": False,
    "GLOO_USE_ROCM": False,
    # Only gloo's CUDA collectives use PyTorch's types.
    "GLOO_USE_TORCH_DTYPES": False,
}

def _substitutions(linux):
    config = _CONFIG | {
        "GLOO_HAVE_TRANSPORT_TCP": linux,
        "GLOO_HAVE_TRANSPORT_UV": not linux,
        "GLOO_USE_LIBUV": not linux,
    }
    return {
        "@GLOO_VERSION_MAJOR@": "0",
        "@GLOO_VERSION_MINOR@": "5",
        "@GLOO_VERSION_PATCH@": "0",
    } | {
        "#cmakedefine01 {}\n".format(name): "#define {} {}\n".format(name, 1 if enabled else 0)
        for name, enabled in config.items()
    }

# The substitutions of gloo/config.h.in: the TCP transport on Linux (it uses
# epoll), and the libuv transport elsewhere (the only one that upstream builds
# with MSVC).
GLOO_CONFIG_SUBSTITUTIONS = select({
    Label("@platforms//os:linux"): _substitutions(linux = True),
    "//conditions:default": _substitutions(linux = False),
})
