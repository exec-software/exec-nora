# Reporting security issues

Use GitHub's private vulnerability reporting for this repository when
available. If no private reporting channel is available, open a minimal issue
requesting one without including exploit details, credentials, or private
data. Ordinary bugs can be reported publicly.

Include your CMake version, compiler, host architecture, the workspace layout
that reproduces the problem, and the relevant Nora log lines. Do not test
against another person's workspace or infrastructure.

## What Nora is, for threat-modelling purposes

Nora is CMake code that runs at configure time with the privileges of whoever
runs `cmake`. It is not a sandbox and does not try to be one:

- It discovers sources and include directories by globbing the workspace, and
  adds every subdirectory holding a `CMakeLists.txt`. Configuring a workspace
  therefore executes the CMake code in those files. Treat an untrusted
  workspace exactly as you would treat an untrusted `CMakeLists.txt`.
- Package resolution writes generated `.pck` files into the discovered vendor
  directory, or into `.packages` inside the build directory, and reads them
  back on later configures. A writable workspace is a writable input.
- Build type and compiler detection choose flags from the host environment.
  `CMAKE_BUILD_TYPE` and the compiler identification are inputs, not
  guarantees.

Report anything that lets a file inside a workspace escape it: a path that
resolves outside the workspace root, a generated file written somewhere other
than `.pipeline`, `.packages` or the vendor directory, or an anchor check that
can be bypassed. `scripts/clean.sh` deletes generated files and refuses to run
without the `.nora` anchor; a way to make it delete something it did not
generate is a security issue, not a bug.

Keep local configuration and secrets outside the source tree. If a credential
is committed, revoke or rotate it and review historical exposure; removing the
current file alone does not remove the credential from Git history.
