# Copyright (C) 2008 - 2026 Execute Software.  All rights reserved.
# SPDX-License-Identifier: MIT

macro( nora_configuration_write_start VAR )
    set( ${VAR} "" )
endmacro()

macro( nora_configuration_write CONFIG NAME )
    set( ${CONFIG} "${${CONFIG}}${NAME}\n${ARGN}\n" )
endmacro()

function( nora_configuration_write_end CONFIG PATH )
    file( WRITE "${PATH}" "${${CONFIG}}" )
endfunction()

function( nora_configuration_read PATH PREFIX GLOBAL )
    file( READ "${PATH}" Contents )
    string( REPLACE ";" "½" Contents "${Contents}" )
    string( REPLACE "\n" ";" Contents "${Contents}" )

    list( LENGTH Contents Length )

    set( i 0 )

    set( break OFF )
    while( NOT ${break} )
        list( GET Contents ${i} Name )
        math( EXPR i "${i} + 1" )
        list( GET Contents ${i} Value )
        string( REPLACE "½" ";" Value "${Value}" )
        math( EXPR i "${i} + 1" )

        if( GLOBAL )
            nora_global_set( "${PREFIX}${Name}" ${Value} )
        else()
            set( "${PREFIX}${Name}" ${Value} )
        endif()

        math( EXPR j "${i} + 2" )
        if( ${j} GREATER ${Length} )
            set( break ON )
        endif()
    endwhile()
endfunction()