# Copyright (C) 2008 - 2026 Execute Software.  All rights reserved.
# SPDX-License-Identifier: MIT

#file(GLOB_RECURSE DLLS ${PIPELINE}/*.dll)
#file(COPY ${DLLS} DESTINATION "${OUTPUT}")

string( REPLACE "'" ";" BINARIES "${BINARIES}" )
if( NOT WIN32 )
    string( REPLACE "\\ ;" ";" BINARIES "${BINARIES}" )
endif()
file( COPY ${BINARIES} DESTINATION "${OUTPUT}" )

if( EXISTS "${PIPELINE}/Runtime" )
    file( COPY "${PIPELINE}/Runtime" DESTINATION "${OUTPUT}" )
endif()