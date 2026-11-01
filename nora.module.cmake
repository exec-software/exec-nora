# Copyright (C) 2008 - 2026 Execute Software.  All rights reserved.
# SPDX-License-Identifier: MIT

cmake_minimum_required( VERSION 3.7 )

####
## Loads the build system and performs any needed configurations
####

enable_language( ASM )

# Assign build system
set( NORA_BUILD_SYSTEM ${NORA_ROOT}/nora/nora.cmake )

# Assign common paths
set( NORA_PATH_PIPELINE ${NORA_ROOT}/.pipeline/${CMAKE_BUILD_TYPE} )
set( NORA_PATH_EXTERN ${NORA_ROOT}/.external ) # Dependencies folder.
set( NORA_PATH_BUILD ${NORA_ROOT}/nora ) # TODO: this should live in a separate pipeline folder.
set( NORA_PATH_BUILD_CMAKE_CACHE ${CMAKE_BINARY_DIR} )

string( SUBSTRING ${NORA_BUILD_SYSTEM} 0 3 NORA_BUILD_SYSTEM_DRIVE )
string( SUBSTRING ${NORA_PATH_BUILD_CMAKE_CACHE} 3 -1 NORA_PATH_BUILD_CMAKE_CACHE_DRIVELESS )
set( NORA_PATH_BUILD_CMAKE_CACHE "${NORA_BUILD_SYSTEM_DRIVE}${NORA_PATH_BUILD_CMAKE_CACHE_DRIVELESS}" )