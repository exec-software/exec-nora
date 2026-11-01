# Nora

Nora is a CMake layer that gives a C++ workspace the kind of project
management an IDE normally provides: you arrange code in directories, and the
build follows the directory tree. Adding a file or a folder does not mean
editing a build script.

## Why it exists

CLion was, for a long time, a CMake-only IDE, and raw CMake is a poor fit for
a workspace of many libraries that are all built together. Every new source
file, every new folder, and every dependency edge meant hand-editing a
`CMakeLists.txt`.

Nora was written to close that gap. The file tree is the source of truth: a
project declares which folders hold its code, and Nora discovers the sources
and the include directories underneath them. In CLion, a Reload CMake Project
is all it takes for new files to join the build.

It began inside a multi-library, multi-platform game engine and was pulled out
once it proved more generally useful. The engine-specific parts are gone; what
is left is the project and package model.

## Requirements

- CMake 3.7 or newer
- A C++17 compiler. The default flag set is written for GCC and Clang; the
  compiler detection also recognises Intel and MSVC.

## Quick start

Nora expects to live inside the workspace it manages:

```
my-workspace/
├── nora/            <- this repository
├── .pipeline/       <- build output, per build type
├── CMakeLists.txt
└── hello/
    ├── CMakeLists.txt
    └── src/
        └── main.cpp
```

Resolved package configuration is written to a `code/vendor` directory if the
workspace has one, which is the useful arrangement when several workspaces
share a vendor tree. Without it, Nora writes into `.packages` inside the build
directory instead; nothing needs to be created by hand.

Prepare the workspace:

```sh
./nora/scripts/install.sh
```

The workspace `CMakeLists.txt` loads Nora, picks up every subdirectory that
has a `CMakeLists.txt` of its own, and finalises at the end:

```cmake
cmake_minimum_required( VERSION 3.7 )

include( ${CMAKE_CURRENT_LIST_DIR}/nora/nora.cmake )

nora_directory_add_all()
nora_finalize()
```

A project describes itself and says what it produces:

```cmake
nora_project_create( Hello )
nora_global_project_description( "A first project" )
nora_project_files_source_add_all( src )
nora_project_install( EXEC )
```

Then configure and build with one of Nora's build types:

```sh
cmake -S . -B build -DCMAKE_BUILD_TYPE=Debug64
cmake --build build
```

The result lands in `.pipeline/Debug64/`.

## Concepts

**Workspace** — the directory that holds Nora and everything it builds. It is
marked by a `.nora` anchor file and is the root for `.pipeline`, `.packages`
and the discovered vendor directory.

**Project** — one build target: an executable, a shared library, a static
library, or nothing at all. Created with `nora_project_create` and given a
kind by `nora_project_install`:

| Kind      | Produces                                        |
|-----------|-------------------------------------------------|
| `EXEC`    | an executable                                   |
| `DYNAMIC` | a shared library                                |
| `STATIC`  | a static library                                |
| `VIRTUAL` | no output; an interface target for grouping     |

**Package** — the metadata behind a project: its include directories, link
directories, libraries, defines and dependencies. Every project gets one
automatically. Packages are what dependency resolution walks, and resolving
them is transitive, so a project inherits the include directories and defines
of what it depends on.

Dependencies are named, not pathed:

```cmake
nora_project_dependency_add( MathLib )
```

## Letting the tree drive the build

`nora_project_files_source_add_all( src )` globs sources beneath `src`.
`nora_project_directory_add_any( src )` goes further and makes every
subdirectory an include root as well, so headers can be included by their bare
name regardless of how deeply they are filed.

This is a deliberate trade. CMake does not re-run a glob on its own, so a file
added on disk is not in the build until CMake is re-run — which is exactly
what CLion's Reload CMake Project does, and why the design works well there.
On a CI machine, configure from clean.

## Build types

Nora defines four, each implying a 64-bit build:

| Type        | Flags                                                   |
|-------------|---------------------------------------------------------|
| `Debug64`   | `-g -O0 -DDEBUG`, defines `NORA_DEBUG`                  |
| `Release64` | `-O3 -s`, defines `NORA_RELEASE`                        |
| `Profile64` | `-O3 -g`, defines `NORA_PROFILE` and `NORA_DEBUG`       |
| `Verify64`  | `-O0 -g` with AddressSanitizer, defines `NORA_VERIFY`   |

Each project is also compiled with `NORA_PLATFORM_<PLATFORM>` and
`NORA_COMPILER_<COMPILER>`, so platform- and compiler-conditional code can
test for them.

## Defines a project receives

| Define | Meaning |
|---|---|
| `NORA_DEBUG`, `NORA_RELEASE`, `NORA_PROFILE`, `NORA_VERIFY` | set to `1` according to the build type |
| `NORA_PLATFORM_<PLATFORM>` | `NORA_PLATFORM_LINUX` or `NORA_PLATFORM_WINDOWS` |
| `NORA_COMPILER_<COMPILER>` | `NORA_COMPILER_GNU`, `NORA_COMPILER_CLANG`, `NORA_COMPILER_MSVC`, `NORA_COMPILER_INTEL` |
| `NORA_API_<PROJECT>` | marks which project is currently being compiled |
| `NORA_EXPORT`, `NORA_IMPORT`, `NORA_NOEXPORT` | the platform's visibility attributes |
| `NORA_EXPORT_<PROJECT>` | export when compiling that project, import when consuming it |
| `NORA_C_EXPORT_<PROJECT>` | the same with `extern "C"` |
| `NORA_PATH_PIPELINE`, `NORA_PATH_BUILD`, `NORA_PATH_EXTERN` | workspace paths, as string literals |
| `NORA_THROW` | `throw` |

`<PROJECT>` is the project name upper-cased with dots replaced by
underscores, so `Libraries.Reflection` becomes `LIBRARIES_REFLECTION`.

A shared library marks its public surface with its own export macro, which
resolves to the export attribute while that project is being built and to the
import attribute everywhere else:

```cpp
NORA_EXPORT_MATHLIB int math_add( int a, int b );
```

## Generated files

Nora writes two kinds of file into the workspace, both reproducible and both
safe to delete:

- `<project>/<Name>.config.md` — a per-project report of what was resolved:
  include directories, links, defines, dependencies and sources. Useful when
  a dependency is not arriving and you want to see what the project actually
  got.
- `<vendor>/<Name>.<BuildType>.pck` — the resolved package configuration, which
  is how one project's package is read by another. This goes to `code/vendor`
  when the workspace has one, otherwise to `.packages` in the build directory.

`./nora/scripts/clean.sh` removes exactly these.

## Output naming

Outputs are named the way the platform names them: `libfoo.so` and `libfoo.a`
on Linux, `foo.dll` with a `foo.lib` import library on Windows, and an
executable with no extension on Linux.

Earlier versions forced the Windows spellings everywhere, because the engine's
packaging step wanted one filename per platform. That is no longer the case.

## Notes for adopters

**Warning flags.** The default set enables `-Wall -Wextra` and then suppresses
a number of checks that were noisy in the codebase Nora grew up in:
`-Wno-unused-function`, `-Wno-unused-parameter`, `-Wno-unused-variable`,
`-Wno-unused-but-set-variable`, `-Wno-unused-but-set-parameter`,
`-Wno-reorder`, `-Wno-maybe-uninitialized` and `-Wno-null-dereference`. These
are tuned to one history, not to yours; `cxx/nora.cxx.flags.cmake` is the one
place to change them.

**Package directories are trusted input.** A `.pck` file supplies a package's
include directories, link directories and libraries, and those feed
`find_library` and the link line. A `.pck` cannot set arbitrary CMake
variables — names are confined to that package's own namespace — but it can
point a build at a library or a header directory of its choosing. Treat the
vendor directory the way you would treat any other vendored dependency
metadata.

**Platform coverage.** Windows and Linux are the platforms Nora knows about.
macOS is not detected and would fall through to the Linux branch.

**The upward search.** Nora locates the vendor directory by walking up from a
project towards the filesystem root, stopping after 24 levels. It will
therefore find, and write into, a `code/vendor` belonging to a directory above
your workspace if one exists. That is deliberate — it is how sibling
workspaces share resolved packages — but it is worth knowing if your workspace
sits inside a larger tree.

## Reference

Every public function is listed in [docs/reference.md](docs/reference.md).

## License

MIT. See [LICENSE](LICENSE).

Copyright (C) 2008 - 2026 Execute Software.
