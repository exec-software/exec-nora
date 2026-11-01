# Copyright (C) 2008 - 2026 Execute Software.  All rights reserved.
# SPDX-License-Identifier: MIT

macro( nora_toolchain_md_prepare VAR )
    set( Nora.Md.Template ${VAR} )
endmacro()

macro( nora_toolchain_md_header NAME )
    set( ${Nora.Md.Template} "${${Nora.Md.Template}}\n# ${NAME}\n" )
endmacro()

macro( nora_toolchain_md_header1 NAME )
    set( ${Nora.Md.Template} "${${Nora.Md.Template}}\n## ${NAME}\n" )
endmacro()

macro( nora_toolchain_md_header2 NAME )
    set( ${Nora.Md.Template} "${${Nora.Md.Template}}\n### ${NAME}\n" )
endmacro()

macro( nora_toolchain_md_text NAME )
    set( ${Nora.Md.Template} "${${Nora.Md.Template}}\n${NAME}\n" )
endmacro()

macro( nora_toolchain_md_option NAME )
    set( ${Nora.Md.Template} "${${Nora.Md.Template}}* ${NAME}\n" )
endmacro()