# Copyright (C) 2008 - 2026 Execute Software.  All rights reserved.
# SPDX-License-Identifier: MIT

nora_global_set( Nora.Cxx.Preprocessors "" )

# Custom configuration types
nora_global_set( CMAKE_CONFIGURATION_TYPES "Debug64;Release64;Profile64;Verify64" )

# add global preprocessor
function( nora_cxx_preprocessor_global_add STR )
    nora_global_set( Nora.Cxx.Preprocessors "${Nora.Cxx.Preprocessors};${STR}" )
endfunction()

# Profile mode?
# Profile also enables debug mode
if( CMAKE_BUILD_TYPE MATCHES "Profile" )
    nora_cxx_preprocessor_global_add( NORA_PROFILE=1 )
    nora_cxx_preprocessor_global_add( NORA_DEBUG=1 )
endif()

# Verify mode?
# Verify also enables debug mode
if( CMAKE_BUILD_TYPE MATCHES "Verify" )
    nora_cxx_preprocessor_global_add( NORA_VERIFY=1 )
    nora_cxx_preprocessor_global_add( NORA_PROFILE=1 )
    nora_cxx_preprocessor_global_add( NORA_DEBUG=1 )
endif()

# Debug mode?
if( CMAKE_BUILD_TYPE MATCHES "Debug" )
    nora_cxx_preprocessor_global_add( NORA_DEBUG=1 )
endif()

# Release mode?
if( CMAKE_BUILD_TYPE MATCHES "Release" )
    nora_cxx_preprocessor_global_add( NORA_RELEASE=1 )
endif()

# DLL Import
# TODO: VC++ dllXXX
if( Nora.Compiler STREQUAL MSVC )
    nora_log_info( "Using MSVC compatible dll linkage" )
    nora_global_set( Nora.Cxx.DLLImport "__declspec(dllimport)" )
    nora_global_set( Nora.Cxx.DLLExport "__declspec(dllexport)" )
    nora_global_set( Nora.Cxx.DLLIgnore "__declspec(dllexport)" )
else()
    if( Nora.Platform STREQUAL Windows )
        nora_log_info( "Using windows compatible dll linkage" )
        nora_global_set( Nora.Cxx.DLLExport "__attribute__ ((dllexport))" )
        nora_global_set( Nora.Cxx.DLLImport "__attribute__ ((dllimport))" )
        nora_global_set( Nora.Cxx.DLLIgnore "__attribute__ ((visibility (\"hidden\")))" )
    else()
        nora_log_info( "Using linux compatible dll linkage" )
        nora_global_set( Nora.Cxx.DLLExport "__attribute__ ((visibility (\"default\")))" )
        nora_global_set( Nora.Cxx.DLLImport "__attribute__ ((visibility (\"default\")))" )
        nora_global_set( Nora.Cxx.DLLIgnore "__attribute__ ((visibility (\"hidden\")))" )
    endif()
endif()

# Includes
include( ${NORA_PATH_BUILD}/cxx/nora.cxx.flags.cmake )
