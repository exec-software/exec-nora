# Copyright (C) 2008 - 2026 Execute Software.  All rights reserved.
# SPDX-License-Identifier: MIT

function( nora_log MESSAGE )
    message( "[Nora] ${MESSAGE}" )
endfunction()

function( nora_log_headerless MESSAGE )
    message( "${MESSAGE}" )
endfunction()

# Error
function( nora_log_error MESSAGE )
    nora_log( " ERROR ${MESSAGE}" )
endfunction()

# Warning
function( nora_log_warning MESSAGE )
    nora_log( " WARNING ${MESSAGE}" )
endfunction()

# Info
function( nora_log_info MESSAGE )
    nora_log( "INFO ${MESSAGE}" )
endfunction()

# Event
function( nora_log_event MESSAGE )
    nora_log( "${MESSAGE}" )
endfunction()


function( nora_log_event_project MESSAGE )
    nora_log_info( "\t\t${MESSAGE}" )
endfunction()