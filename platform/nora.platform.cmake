# Copyright (C) 2008 - 2026 Execute Software.  All rights reserved.
# SPDX-License-Identifier: MIT

# Get the platform-specific include directory name.

macro( nora_platform_path_include OUT )
    if( Nora.Platform STREQUAL Windows )
        set( ${OUT} "IncludeWindows" )
    elseif( Nora.Platform STREQUAL Linux )
        set( ${OUT} "IncludeLinux" )
    else()
        nora_log_error( "Unknown platform: '${Nora.Platform}'" )
    endif()
endmacro()