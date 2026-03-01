# C++ Template

A zero-dependency C++ project template. [Zig](https://ziglang.org) replaces the usual tools: `gcc`,
`cmake`, `ninja`, `ccache`.

## Setup

Create a repo from this template using _Use this template_ above, or clone the repo:

```sh
$ git clone https://github.com/fng97/cpp-template.git
```

Install Zig using the polyglot script ([copied from
TigerBeetle](https://github.com/tigerbeetle/tigerbeetle/blob/main/zig/download.ps1)):

```sh
$ ./zig/download.ps1  # linux/macos
```

```ps1
$ .\zig\download.ps1  # windows
```

## Entrypoint

On Windows, use `.\zig\zig.exe` instead of `./zig/zig`.

```plaintext
$ ./zig/zig build --help
Usage: /path/to/zig/zig build [steps] [options]

Steps:
  install (default)            Copy build artifacts to prefix path
  uninstall                    Remove build artifacts from prefix path
  run                          Run the main executable
  gtest                        Run googletest
  gbench                       Run google benchmark
  test                         Run all checks
  fmt                          Format C/C++ files with clang-format

$ ./zig/zig build test  # runs tests, benchmarks, and checks formatting
```

## Bundled Packages

This project includes three common packages:
[googletest](https://github.com/allyourcodebase/googletest), [Google
Benchmark](https://github.com/allyourcodebase/benchmark), and
[`clang-format`](https://github.com/fng97/clang-tools). These are installed by the build system.
