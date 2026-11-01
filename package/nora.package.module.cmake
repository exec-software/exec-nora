# Copyright (C) 2008 - 2026 Execute Software.  All rights reserved.
# SPDX-License-Identifier: MIT

####
## Prepares the internal package system
####

# Package List
set( Nora.Packages "" CACHE INTERNAL "" FORCE )

# Includes
include( ${NORA_PATH_BUILD}/package/nora.package.cmake )
include( ${NORA_PATH_BUILD}/package/nora.package.resolve.cmake )