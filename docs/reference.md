# Nora reference

Every public function and macro, grouped by the file that defines it. Names
are stable; anything not listed here is internal.

A note on two conventions that run through the API. Most `nora_project_*` and
`nora_package_*` calls act on the project or package most recently created in
the current `CMakeLists.txt`, so they are written after `nora_project_create`
and need no target argument. And a directory argument is taken relative to the
`CMakeLists.txt` that supplies it, unless it is already absolute, in which
case it is used as given.

## Workspace

### `nora_finalize()`
Resolves every package, configures every project, and creates the targets.
Call it once, last, in the workspace `CMakeLists.txt`. It only acts when
invoked from the top-level source directory, so it is harmless in a
subdirectory.

### `nora_directory_add_all()`
Adds every immediate subdirectory that contains a `CMakeLists.txt`. Hidden
directories are skipped.

### `nora_directory_add( <dir>... )`
Adds the named subdirectories explicitly.

## Projects

### `nora_project_create( <name> )`
Declares a project and makes it current. Also creates its package, calls
CMake's `project()`, applies the default flags for the build type, adds an
`Include` directory if one exists beside the `CMakeLists.txt`, and defines the
project's export macros. A name may contain dots.

### `nora_project_install( EXEC | DYNAMIC | STATIC | VIRTUAL )`
Declares what the project produces. `VIRTUAL` produces no artefact and yields
an interface target, which is useful for grouping.

### `nora_project_test_create( <project> [<dir>...] )`
Creates `<project>.Test`, depends it on `<project>`, adds sources from the
given directories, and installs it as `EXEC`.

### `nora_global_project_description( <text> )`
Sets the description recorded in the package and the generated report.

### `nora_global_project_path_build( <path> )`
Overrides where the project's output goes. A relative path is taken from the
project directory. The build type is appended, and the directory is created.

### `nora_project_build_name_set( <name> )`
Sets the installed artefact name, when it should differ from the project name.

### `nora_project_build_mode_set( <mode> )`
Recomputes this project's flags for a different build type than the one the
workspace is configured with.

### `nora_project_attribute_set( <name> [<value>] )`
Sets `Attr<name>` on the project. With no value, sets it to `ON`.

### `nora_project_load_order( AFTER | BEFORE, <project>... )`
Records a load-order relationship, carried through to the generated package
configuration.

## Sources and directories

### `nora_project_files_source_add_all( <dir>... )`
Globs `*.h`, `*.cpp`, `*.asm` and `*.S` recursively beneath each directory and
adds them as the project's sources.

Platform-specific directories can be named with an upper-case platform
keyword, and only the matching platform's directories are used:

```cmake
nora_project_files_source_add_all( src WINDOWS src/win LINUX src/posix )
```

### `nora_project_source_set( <file>... )`
Adds individual source files.

### `nora_project_directory_include_add( [GLOBAL] <dir>... )`
Adds include directories. `GLOBAL` marks arguments that must be used exactly
as given.

### `nora_project_files_include_add_all( <dir>... )`
Adds each directory beneath the given ones as an include directory, so headers
can be included by bare name.

### `nora_project_directory_add_source_any( <dir>... )`
Adds sources from each subdirectory beneath the given ones.

### `nora_project_directory_add_any( <dir>... )`
Both of the above: every subdirectory becomes an include root and contributes
its sources. This is the usual call for a project whose headers and sources
share a tree.

### `nora_project_directory_external_include_add_any( <dir>... )`
Adds include directories as SYSTEM, which exempts them from the project's
warning flags. Use it for third-party headers.

## Dependencies and linking

### `nora_project_dependency_add( <project>... )`
Declares a dependency on another Nora project, by name. Include directories
and defines are inherited transitively, and the library is linked.

### `nora_project_link_add( <library>... )`
Links libraries by name, resolved with `find_library` against the project's
link directories.

### `nora_project_directory_link_add( <dir>... )`
Adds directories to search for libraries.

### `nora_project_external_link_add( <library>... )`
Links libraries that are not Nora packages.

### `nora_project_external_binary_add( <file>... )`
Names binaries to be copied beside an executable's output.

### `nora_project_definitions_add( <define>... )`
Adds preprocessor definitions.

## Packages

A project creates its own package, so these are rarely called directly.

### `nora_package_create( <name> <out-var> )`
Creates a package and writes its variable prefix into `<out-var>`.

### `nora_package_finalize()`
Writes every package's `.pck` configuration. Called by `nora_finalize`.

### `nora_project_configure_all()`
Creates the CMake target for every declared project and applies its sources,
flags, include directories, links and defines. Called by `nora_finalize`.

### `nora_package_resolve( <name> )`, `nora_package_resolve_all()`, `nora_package_resolve_search_all()`
Resolve dependencies, transitively, reading `.pck` files from a package's
search paths for dependencies that are not projects in this build.

### `nora_package_directory_include_add( [GLOBAL] <dir>... )`, `nora_package_directory_include_external_add( [GLOBAL] <dir>... )`, `nora_package_directory_link_add( <dir>... )`, `nora_package_link_add_many( <library>... )`, `nora_package_link_external_add( <library>... )`, `nora_package_binary_external_add( <file>... )`, `nora_package_definitions_add( <define>... )`, `nora_package_dependency_add( <package>... )`, `nora_package_load_order( AFTER | BEFORE, <package>... )`
The package-level forms of the project calls above.

### `nora_global_package_installed_set( <name> <type> )`, `nora_global_package_description_set( <text> )`, `nora_global_package_build_path_set( <path> )`
Set the installed artefact, the description, and the output path.

## Logging

All logging goes to CMake's `message()`. Each function takes **one** argument,
so compose the string before passing it.

| Function | Output |
|---|---|
| `nora_log( <msg> )` | `[Nora] <msg>` |
| `nora_log_info( <msg> )` | `[Nora] INFO <msg>` |
| `nora_log_warning( <msg> )` | `[Nora]  WARNING <msg>` |
| `nora_log_error( <msg> )` | `[Nora]  ERROR <msg>` |
| `nora_log_event( <msg> )` | `[Nora] <msg>` |
| `nora_log_event_project( <msg> )` | indented, for nested detail |
| `nora_log_headerless( <msg> )` | no prefix |

`nora_log_error` reports; it does not stop the configure.

## Utilities

### `nora_global_set( <name> <value>... )`
Sets a cache variable that survives across directory scopes. This is how Nora
keeps project and package state.

### `nora_prefix( <list> <out> <prefix> )` / `nora_postfix( <list> <out> <postfix> )`
String prefix or suffix on every entry of a list.

### `nora_path_prefix( <list> <out> <prefix> )`
As `nora_prefix`, but leaves entries that are already absolute untouched. Use
this whenever the prefix is a directory.

### `nora_file_write( <path> <contents> )`
Writes a file only when the contents differ, so timestamps — and rebuilds —
are not disturbed needlessly.

### `nora_configuration_write_start( <var> )`, `nora_configuration_write( <var> <name> <value>... )`, `nora_configuration_write_end( <var> <path> )`, `nora_configuration_read( <path> <prefix> <global> )`
The key/value format behind `.pck` files. `nora_configuration_read` prefixes
every name it reads, so a configuration file can only populate its own
namespace.

### `nora_object_path_get( <target> <source> <out> )`
Computes the object file path a source will compile to.

### `nora_platform_path_include( <out> )`
Writes the platform's include directory name, `IncludeWindows` or
`IncludeLinux`.

### `nora_cxx_flags_set( <out-cxx> <out-c> <out-linker> <build-type> )`
Computes the compile and link flags for a build type.

### `nora_cxx_preprocessor_global_add( <define> )`
Adds a define to every project in the workspace.

## Markdown generation

Used to build the per-project report, and available for any generated
Markdown.

`nora_toolchain_md_prepare( <var> )`, `nora_toolchain_md_header( <text> )`,
`nora_toolchain_md_header1( <text> )`, `nora_toolchain_md_header2( <text> )`,
`nora_toolchain_md_text( <text> )`, `nora_toolchain_md_option( <text> )`
