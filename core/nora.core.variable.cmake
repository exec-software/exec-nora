# Copyright (C) 2008 - 2026 Execute Software.  All rights reserved.
# SPDX-License-Identifier: MIT

# Set global variable
function( nora_global_set NAME )
    # nora_logevent( "\tRegistering core global ${NAME}" )
    set( ${NAME} "${ARGN}" CACHE INTERNAL "" FORCE )
endfunction()

# Prefix all
macro( nora_prefix VAR OUT PREFIX )
    set( ${OUT} "" )
    foreach( F ${VAR} )
        list( APPEND ${OUT} "${PREFIX}${F}" )
    endforeach()
endmacro()

# Join a directory prefix onto each entry, leaving entries that are already
# absolute alone.
#
# nora_prefix is a string operation and will happily produce
# '<project>//home/me/thing', which is not a directory that can exist. Every
# caller that joins a base directory onto a list of paths wants this instead:
# the recurse resolver yields absolute directories while a hand-written
# CMakeLists.txt yields relative ones, and both must survive the same call.
macro( nora_path_prefix VAR OUT PREFIX )
    set( ${OUT} "" )
    foreach( F ${VAR} )
        if( IS_ABSOLUTE "${F}" )
            list( APPEND ${OUT} "${F}" )
        else()
            list( APPEND ${OUT} "${PREFIX}${F}" )
        endif()
    endforeach()
endmacro()

# Postfix all
macro( nora_postfix VAR OUT POSTFIX )
    set( ${OUT} "" )
    foreach( F ${VAR} )
        list( APPEND ${OUT} "${F}${POSTFIX}" )
    endforeach()
endmacro()