# Contributing to Nora

Contributions to the project and package model, directory discovery, build
types, compiler and platform detection, documentation, and examples are
welcome. For a bug report, include your CMake version, compiler, host
architecture, the workspace layout that reproduces it, and the Nora log lines
leading up to the problem.

Execute Software and community contributors are recognized in
[CONTRIBUTORS.md](CONTRIBUTORS.md). You may add your preferred name to the
community section when submitting a contribution.

Open an issue describing the change before reworking a public `nora_*`
contract. Adopting workspaces call those names directly from their own
`CMakeLists.txt`, so a rename is a breaking change for every one of them.

## Development workflow

Nora expects to be checked out as `<workspace>/nora` and to manage the
workspace around it, so it cannot be built on its own. Build a workspace
instead:

1. Prepare the layout and the `.nora` anchor with `./scripts/install.sh`.
2. Declare at least one project, as the [README](README.md) quick start shows.
3. Configure from clean and build:

```sh
cmake -S . -B build -DCMAKE_BUILD_TYPE=Debug64
cmake --build build
```

The result lands in `.pipeline/<build type>/`. Check `Debug64` and `Release64`
at minimum; their flag sets differ. CMake does not re-run a glob on its own,
so configure from clean rather than expecting a new source file to appear in an
existing build.

`./scripts/clean.sh` removes what Nora generates into the workspace: the
per-project `<Name>.config.md` reports and the resolved `<Name>.<Type>.pck`
package files. It refuses to run without the `.nora` anchor.

The default flag set targets x86-64 with GCC or Clang. It includes `-msse`,
`-msse2`, `-msse3` and `-mmmx`, which Clang rejects for arm64, so an Apple
Silicon or AArch64 change has to make those conditional in
`cxx/nora.cxx.flags.cmake` rather than simply removing them: adopting
workspaces depend on the current codegen. The continuous integration workflow
builds Debug64 and Release64 on x86-64 Linux.

Do not commit credentials, private project notes, local service addresses,
developer-specific paths, or generated build artifacts. Nora's own
`.gitignore` covers the workspace directories it creates, but a workspace
opened with Nora checked out inside it can still stage files from outside.

For a local secret scan, install
[Gitleaks 8.30.1](https://github.com/gitleaks/gitleaks/releases/tag/v8.30.1)
and run these commands from the repository root. Choose a new report directory
outside the checkout:

```sh
python3 scripts/test_audit_secrets.py
python3 scripts/audit_secrets.py --scanner /path/to/gitleaks --report-dir ../nora-audit
```

The helper scans tracked and non-ignored source files, staged changes, and all
local Git refs. It refuses symlinks and submodules, keeps redacted reports
outside the checkout, and ignores inline scanner-suppression comments. The
source-audit workflow installs the same scanner from a checksum-pinned release
and does not upload reports. Never paste a scanner report into a public issue
or pull request: even redacted findings can reveal private surrounding
context.

## Documentation

Every public function is listed in [docs/reference.md](docs/reference.md).
Update it in the same change as the function. The README documents which
warning checks are deliberately off; that list was tuned against a large
existing codebase, so tightening it is a decision for whoever adopts Nora
rather than something to change here silently.

Contributions use the repository's [MIT License](LICENSE).
