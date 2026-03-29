# C++ Template

A C++ project template using [Zig](https://ziglang.org) for the build system
instead of the usual tools: `clang`, `cmake`, `ninja`, and `ccache`.

The template bundles your typical C++ testing, benchmarking, and formatting
dependencies (ported to Zig):
[googletest](https://github.com/allyourcodebase/googletest), [Google
Benchmark](https://github.com/allyourcodebase/benchmark), and
[`clang-format`](https://github.com/fng97/clang-tools).

## Usage

[Install Zig](https://ziglang.org/learn/getting-started/). Check out
[anyzig](https://github.com/marler8997/anyzig) if you want a single `zig`
executable for all versions of Zig.

The build system entrypoints are:

```console
$ zig build --help
Usage: /path/to/zig/zig build [steps] [options]

Steps:
  install (default)            Copy build artifacts to prefix path
  uninstall                    Remove build artifacts from prefix path
  run                          Run the main executable
  gtest                        Run googletest
  gbench                       Run google benchmark
  test                         Run all checks
  fmt                          Format C/C++ files with clang-format

$ zig build test  # runs tests, benchmarks (single iter each), checks formatting
```
