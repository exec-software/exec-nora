# Copyright (C) 2008 - 2026 Execute Software.  All rights reserved.
# SPDX-License-Identifier: MIT

get_property( NORA_CONFIGURED GLOBAL PROPERTY NORA_CONFIGURED )

# Already configured?
if( NOT NORA_CONFIGURED )
    # Root must exist in current directory
    if( NOT EXISTS "${CMAKE_CURRENT_LIST_DIR}/../nora" )
        message( FATAL_ERROR "Nora root folder misplaced, expected directory '.../nora' but got '${CMAKE_CURRENT_LIST_DIR}'" )
    endif()

    # Root
    set( NORA_ROOT "${CMAKE_CURRENT_LIST_DIR}/.." CACHE INTERNAL "FULL_PATH" )

    message( "Registered root @ ${NORA_ROOT}." )

    # Clear Nora.* cache entries from a previous configure, so a removed
    # package or project does not linger in the cache.
    get_cmake_property( CACHED_VARIABLES VARIABLES )
    foreach( Var ${CACHED_VARIABLES} )
        string( FIND "${Var}" "Nora." INDEX )
        if( ${INDEX} EQUAL 0 )
            unset( ${Var} CACHE )
        endif()
    endforeach()
    message( STATUS "Cleaned up previous cache" )

    # Mark as configured
    set_property( GLOBAL PROPERTY NORA_CONFIGURED "ON" )

    # Configure this
    include( ${NORA_ROOT}/nora/nora.module.cmake )

    # Configure sub systems
    include( ${NORA_PATH_BUILD}/core/nora.core.module.cmake )
    include( ${NORA_PATH_BUILD}/compiler/nora.compiler.module.cmake )
    include( ${NORA_PATH_BUILD}/platform/nora.platform.module.cmake )
    include( ${NORA_PATH_BUILD}/package/nora.package.module.cmake )
    include( ${NORA_PATH_BUILD}/project/nora.project.module.cmake )
    include( ${NORA_PATH_BUILD}/cxx/nora.cxx.module.cmake )

    # Done
    nora_log_event( "Nora build engine ready." )
endif()

# Finalize build system
macro( nora_finalize )
    if( "${CMAKE_CURRENT_LIST_DIR}" STREQUAL "${CMAKE_SOURCE_DIR}" )
        nora_package_finalize()
        nora_package_resolve_search_all()
        nora_package_resolve_all()
        nora_project_configure_all()
        nora_log_event( "Generation complete!" )
    endif()
endmacro()