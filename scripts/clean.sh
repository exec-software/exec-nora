#!/usr/bin/env bash
# Copyright (C) 2008 - 2026 Execute Software.  All rights reserved.
# SPDX-License-Identifier: MIT
#
# Remove the files Nora generates into the workspace it manages.
#
# Nora writes two kinds of generated file next to the sources it describes:
#
#   <project>/<Name>.config.md      the per-project report
#   <packagedir>/<Name>.<Type>.pck  the resolved package configuration
#
# This script used to run 'find ../../ -type f -name "*.md" -delete', which
# deleted every Markdown file two levels above the working directory. That is
# far wider than the reports it meant to remove: it also took hand-written
# documentation, including sibling projects' own README files, and because the
# path was relative to the working directory rather than to the script, what
# it destroyed depended on where it was run from.

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
workspace="$(cd -- "${script_dir}/../.." && pwd)"

if [[ ! -e "${workspace}/.nora" ]]; then
  printf 'error: %s is not a Nora workspace (no .nora anchor)\n' "${workspace}" >&2
  printf 'Run scripts/install.sh first, or pass the workspace explicitly.\n' >&2
  exit 1
fi

removed=0
while IFS= read -r -d '' file; do
  printf 'removing %s\n' "${file#"${workspace}/"}"
  rm -f -- "${file}"
  removed=$((removed + 1))
done < <(find "${workspace}" \
  \( -name '*.config.md' -o -name '*.pck' \) \
  -type f -print0)

printf 'Removed %d generated file(s) under %s\n' "${removed}" "${workspace}"
