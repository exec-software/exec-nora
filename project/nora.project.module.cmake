# Copyright (C) 2008 - 2026 Execute Software.  All rights reserved.
# SPDX-License-Identifier: MIT

####
## Prepares the internal project system
####

# project List
set( Nora.Projects "" CACHE INTERNAL "" FORCE )

# Includes
include( ${NORA_PATH_BUILD}/project/nora.project.cmake )
include( ${NORA_PATH_BUILD}/project/nora.project.configuration.cmake )