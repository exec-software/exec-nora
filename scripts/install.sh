#!/usr/bin/env bash
# Copyright (C) 2008 - 2026 Execute Software.  All rights reserved.
# SPDX-License-Identifier: MIT
#
# Prepare a Nora workspace.
#
# Nora expects to be checked out as <workspace>/nora and to manage the
# workspace around it. This creates the directories it looks for and the
# .nora anchor that marks the workspace root.
#
# Paths are resolved from this script's own location. They used to be relative
# to the working directory ('mkdir ../../.pipeline'), so running the script
# from anywhere other than scripts/ created the layout in the wrong place.
# mkdir also ran without -p, so a second run failed once the directories
# existed.

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
workspace="$(cd -- "${script_dir}/../.." && pwd)"

printf 'Preparing Nora workspace at %s\n' "${workspace}"

for dir in .pipeline .packages sandbox; do
  mkdir -p -- "${workspace}/${dir}"
  printf '  %s/\n' "${dir}"
done

# The anchor marks the workspace root. clean.sh refuses to run without it.
if [[ ! -e "${workspace}/.nora" ]]; then
  : > "${workspace}/.nora"
  printf '  .nora\n'
fi

printf 'Done.  Add an include( nora/nora.cmake ) and a nora_finalize() to the\n'
printf 'workspace CMakeLists.txt to start declaring projects.\n'
