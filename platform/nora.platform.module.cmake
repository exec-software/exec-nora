# Copyright (C) 2008 - 2026 Execute Software.  All rights reserved.
# SPDX-License-Identifier: MIT

####
## Prepares the platform config
####

### CONFIG

# Available platforms
set( Nora.Platforms Windows Linux )

# TODO: Detect
set( Nora.Platform Windows )
if( WIN32 )
    set( Nora.Platform Windows )
elseif( UNIX )
    set( Nora.Platform Linux )
endif()

# Windows configuration
set( Nora.Platform.Windows.Preprocessors WINVER=0x0600 _WIN32_WINNT=0x0600 )

### /CONFIG

# To uppercase
set( Nora.Platforms.Uppercase "" )
foreach( Platform ${Nora.Platforms} )
    string( TOUPPER ${Platform} Str )
    list( APPEND Nora.Platforms.Uppercase ${Str} )
endforeach()

# To uppercase
string( TOUPPER ${Nora.Platform} Nora.Platform.Uppercase )

# Includes
include( ${NORA_PATH_BUILD}/platform/nora.platform.cmake )