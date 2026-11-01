# Copyright (C) 2008 - 2026 Execute Software.  All rights reserved.
# SPDX-License-Identifier: MIT

# Detect the current core
if( "${CMAKE_CXX_COMPILER_ID}" STREQUAL "Clang" )
    nora_global_set( Nora.Compiler "CLANG" )
elseif( "${CMAKE_CXX_COMPILER_ID}" STREQUAL "GNU" )
    nora_global_set( Nora.Compiler "GNU" )
elseif( "${CMAKE_CXX_COMPILER_ID}" STREQUAL "Intel" )
    nora_global_set( Nora.Compiler "Intel" )
elseif( "${CMAKE_CXX_COMPILER_ID}" STREQUAL "MSVC" )
    nora_global_set( Nora.Compiler "MSVC" )
endif()

# To uppercase.
# This read 'nora_global_set( TOUPPER ... )', which is not how a string is
# upper-cased: it set a cache variable literally named TOUPPER to
# "GNU;Nora.Compiler.Uppercase" and left Nora.Compiler.Uppercase empty. Every
# project was then compiled with a bare 'NORA_COMPILER_' define instead of
# NORA_COMPILER_GNU, so compiler-conditional code in a consumer never matched.
# The platform module two files over has always done this correctly.
string( TOUPPER "${Nora.Compiler}" Nora.Compiler.Uppercase )
nora_global_set( Nora.Compiler.Uppercase "${Nora.Compiler.Uppercase}" )

# Default preprocessors
nora_global_set( Nora.Compiler.Preprocessors "" )