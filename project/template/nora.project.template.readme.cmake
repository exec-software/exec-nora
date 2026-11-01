# Copyright (C) 2008 - 2026 Execute Software.  All rights reserved.
# SPDX-License-Identifier: MIT

include( ${NORA_PATH_BUILD}/toolchain/nora.toolchain.md.cmake )
nora_toolchain_md_prepare( TEMPLATE )

nora_toolchain_md_header( "${${LocalProject}.Name} - Report" )

nora_toolchain_md_text( "**Path:** `${${LocalPackage}.Dir}`" )
nora_toolchain_md_text( "**Build Path:** `${${${LocalProject}.Package}.BuildPath}`" )

# INSTALLED
nora_toolchain_md_header1( "Installed:" )
foreach( Var ${${LocalPackage}.Installed} )
    nora_toolchain_md_option( "`${Var}`" )
endforeach()

# DEFINES
nora_toolchain_md_header1( "Defines:" )
foreach( Var ${${LocalPackage}.AllDefines} )
    nora_toolchain_md_option( "`${Var}`" )
endforeach()

# DEPENDENCIES
nora_toolchain_md_header1( "Dependencies:" )
foreach( Var ${${LocalPackage}.Dependencies} )
    nora_toolchain_md_option( "`${Var}`" )
endforeach()

# INCLUDES
nora_toolchain_md_header1( "Include directories:" )
foreach( Var ${${LocalPackage}.IncludeDirs} )
    nora_toolchain_md_option( "`${Var}`" )
endforeach()

# INCLUDES
nora_toolchain_md_header1( "External Include directories:" )
nora_toolchain_md_text( "    (Exempt from diagnostics such as extra compiler warnings)" )
foreach( Var ${${LocalPackage}.ExternIncludeDirs} )
    nora_toolchain_md_option( "`${Var}`" )
endforeach()

# LINK INCLUDES
nora_toolchain_md_header1( "Link directories:" )
foreach( Var ${${LocalPackage}.LinkDirs} )
    nora_toolchain_md_option( "`${Var}`" )
endforeach()

# LINKS
nora_toolchain_md_header1( "Links:" )
foreach( Var ${${LocalPackage}.Links} )
    nora_toolchain_md_option( "`${Var}`" )
endforeach()

# SOURCES
nora_toolchain_md_header1( "Sources:" )
foreach( Var ${${LocalProject}.Sources} )
    nora_toolchain_md_option( "`${Var}`" )
endforeach()