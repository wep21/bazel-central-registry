"""Code generation and compiler flags shared by libsleef and its tests.

The flags follow Configure.cmake, and the code generation the custom commands
of src/libm/CMakeLists.txt.
"""

# SLEEF_C_FLAGS and C_STANDARD 99 (-std=gnu99) of Configure.cmake. MSVC gets
# only the /D_CRT_* definitions of its FLAGS_WALL.
SLEEF_COPTS = select({
    Label("@rules_cc//cc/compiler:msvc-cl"): [
        "/D_CRT_SECURE_NO_WARNINGS",
        "/D_CRT_NONSTDC_NO_DEPRECATE",
    ],
    "//conditions:default": [
        "-std=gnu99",
        "-Wno-unused-function",
        "-Wno-attributes",
        "-Wno-unused-result",
        # Always compile sleef with -ffp-contract=off.
        "-ffp-contract=off",
        # Without these, GCC generates calls to libm.
        "-fno-math-errno",
        "-fno-trapping-math",
    ],
}) + select({
    # "AVX vector return without AVX enabled changes the ABI".
    Label("@rules_cc//cc/compiler:gcc"): ["-Wno-psabi"],
    Label("@rules_cc//cc/compiler:mingw-gcc"): [
        "-Wno-psabi",
        "-fno-asynchronous-unwind-tables",
    ],
    "//conditions:default": [],
})

# COMMON_TARGET_DEFINITIONS: static libraries, weak aliases (an ELF feature)
# and getrandom(2).
SLEEF_DEFINES = ["SLEEF_STATIC_LIBS=1"] + select({
    Label("@platforms//os:linux"): [
        "ENABLE_ALIAS=1",
        "ENABLE_SYS_getrandom=1",
    ],
    "//conditions:default": [],
})

# COMPILER_SUPPORTS_BUILTIN_MATH (__builtin_sqrt), which MSVC lacks.
SLEEF_BUILTIN_MATH_DEFINES = select({
    Label("@rules_cc//cc/compiler:msvc-cl"): [],
    "//conditions:default": ["ENABLE_BUILTIN_MATH=1"],
})

# FLAGS_ENABLE_<extension> for GCC and Clang (CLANG_FLAGS_ENABLE_*), per
# architecture.
_FLAGS = {
    "aarch64": {
        "SVE": ["-march=armv8-a+sve"],
        "SVENOFMA": ["-march=armv8-a+sve"],
    },
    "x86_64": {
        "AVX": ["-mavx"],
        "AVX2": [
            "-mavx2",
            "-mfma",
        ],
        "AVX2128": [
            "-mavx2",
            "-mfma",
        ],
        "AVX512F": ["-mavx512f"],
        "AVX512FNOFMA": ["-mavx512f"],
        "FMA4": ["-mfma4"],
        "PURECFMA_SCALAR": [
            "-mavx2",
            "-mfma",
        ],
        "SSE2": ["-msse2"],
        "SSE4": ["-msse4.1"],
    },
}

# FLAGS_ENABLE_<extension> for MSVC on x86_64 (CMAKE_CL_64).
_MSVC_FLAGS = {
    "AVX": [
        "/D__SSE2__",
        "/D__SSE3__",
        "/D__SSE4_1__",
        "/D__AVX__",
        "/arch:AVX",
    ],
    "AVX2": [
        "/D__SSE2__",
        "/D__SSE3__",
        "/D__SSE4_1__",
        "/D__AVX__",
        "/D__AVX2__",
        "/arch:AVX2",
    ],
    "AVX2128": [
        "/D__SSE2__",
        "/D__SSE3__",
        "/D__SSE4_1__",
        "/D__AVX__",
        "/D__AVX2__",
        "/arch:AVX2",
    ],
    "AVX512F": [
        "/D__SSE2__",
        "/D__SSE3__",
        "/D__SSE4_1__",
        "/D__AVX__",
        "/D__AVX2__",
        "/D__AVX512F__",
        "/arch:AVX2",
    ],
    "AVX512FNOFMA": [
        "/D__SSE2__",
        "/D__SSE3__",
        "/D__SSE4_1__",
        "/D__AVX__",
        "/D__AVX2__",
        "/D__AVX512F__",
        "/arch:AVX2",
    ],
    "PURECFMA_SCALAR": [
        "/D__SSE2__",
        "/D__SSE3__",
        "/D__SSE4_1__",
        "/D__AVX__",
        "/D__AVX2__",
        "/arch:AVX2",
    ],
    "SSE2": ["/D__SSE2__"],
    "SSE4": [
        "/D__SSE2__",
        "/D__SSE3__",
        "/D__SSE4_1__",
    ],
}

def sleef_extension_copts(extension):
    """Returns the compiler flags enabling a vector extension (FLAGS_ENABLE_*).

    Args:
      extension: the name of the extension in Configure.cmake, e.g. "AVX2".

    Returns:
      The flags for the target's architecture and compiler.
    """
    return select({
        Label("//:x86_64_msvc"): _MSVC_FLAGS.get(extension, []),
        Label("//:x86_64"): _FLAGS["x86_64"].get(extension, []),
        Label("//:aarch64"): _FLAGS["aarch64"].get(extension, []),
        "//conditions:default": [],
    }) + (select({
        # Configure.cmake works around a GCC bug with SVE.
        Label("@rules_cc//cc/compiler:gcc"): ["-fno-tree-vrp"],
        "//conditions:default": [],
    }) if extension == "SVE" else [])

def _generate_impl(ctx):
    ctx.actions.run(
        executable = ctx.executable.tool,
        arguments = [ctx.outputs.out.path] + ctx.attr.arguments,
        outputs = [ctx.outputs.out],
        mnemonic = "SleefGenerate",
        progress_message = "Generating %{output}",
    )

# Writes the output of one of the generators (see bazel/tool_main.c).
sleef_generate = rule(
    implementation = _generate_impl,
    attrs = {
        "arguments": attr.string_list(),
        "out": attr.output(mandatory = True),
        "tool": attr.label(mandatory = True, executable = True, cfg = "exec"),
    },
)

def _concat_impl(ctx):
    ctx.actions.run(
        executable = ctx.executable._concat,
        arguments = [ctx.outputs.out.path] + [f.path for f in ctx.files.srcs],
        inputs = ctx.files.srcs,
        outputs = [ctx.outputs.out],
        mnemonic = "SleefConcat",
        progress_message = "Generating %{output}",
    )

# Concatenates files (sleef_concat_files() in upstream's CMake build).
sleef_concat = rule(
    implementation = _concat_impl,
    attrs = {
        "out": attr.output(mandatory = True),
        "srcs": attr.label_list(allow_files = True),
        "_concat": attr.label(default = Label("//bazel:concat"), executable = True, cfg = "exec"),
    },
)
