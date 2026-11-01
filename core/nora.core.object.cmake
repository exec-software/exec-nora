# Copyright (C) 2008 - 2026 Execute Software.  All rights reserved.
# SPDX-License-Identifier: MIT

function( nora_object_path_get TARGET SOURCE OUTPUT )
    if( MSVC )
        # This body sat inside 'foreach( f ${source_files} )'. source_files is
        # set nowhere in this project, so the loop ran zero times and OUTPUT
        # came back unset on MSVC. The body never used f either -- it derives
        # everything from SOURCE -- so the loop only ever suppressed it. The
        # non-MSVC branch below has always computed this once, without a loop.
        get_filename_component( fname ${SOURCE} NAME )
        string( REPLACE ".cpp" ".obj" fname2 ${fname} )
        string( REPLACE ".c" ".obj" fname2 ${fname2} )
        if( MSVC60 )
            set( ${OUTPUT} "${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_CFG_INTDIR}/${fname2}" PARENT_SCOPE )
        else()
            set( ${OUTPUT} "${CMAKE_CURRENT_BINARY_DIR}/${TARGET}.dir/${CMAKE_CFG_INTDIR}/${fname2}" PARENT_SCOPE )
        endif()
    else()
        # Backwards compat to core <= 2.8.4
        if( "${CMAKE_CURRENT_LIST_DIR}" STREQUAL "" )
            get_filename_component( CMAKE_CURRENT_LIST_DIR ${CMAKE_CURRENT_LIST_FILE} PATH ABSOLUTE )
        endif()

        #GET_FILENAME_COMPONENT(fname ${SOURCE} NAME)
        string( REPLACE "${CMAKE_CURRENT_LIST_DIR}/" "" fname "${SOURCE}" )
        if( WIN32 )
            set( ${OUTPUT} "${CMAKE_CURRENT_BINARY_DIR}/CMakeFiles/${TARGET}.dir/${fname}.obj" PARENT_SCOPE )
        else()
            set( ${OUTPUT} "${CMAKE_CURRENT_BINARY_DIR}/CMakeFiles/${TARGET}.dir/${fname}.o" PARENT_SCOPE )
        endif()
    endif()

endfunction()