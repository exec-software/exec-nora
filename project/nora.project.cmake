# Copyright (C) 2008 - 2026 Execute Software.  All rights reserved.
# SPDX-License-Identifier: MIT

# Create project
# @Name: Name of the project
function( nora_project_create NAME )
    # Must not exist
    if( NOT "${Nora.Projects.${NAME}.Name}" STREQUAL "" )
        nora_log_error( "Project with name '${NAME}' already exists" )
    endif()
    nora_log_headerless( "\n\n##################################################################################" )
    nora_log_info( "Creating project ${NAME}" )
    nora_log_headerless( "##################################################################################\n" )

    # append
    list( APPEND Nora.Projects ${NAME} )
    nora_global_set( Nora.Projects "${Nora.Projects}" )

    # Initialize variables
    nora_global_set( "Nora.Projects.${NAME}.Name" "${NAME}" )
    nora_global_set( "Nora.Projects.${NAME}.InstallName" "${NAME}" )
    nora_global_set( "Nora.Projects.${NAME}.Deps" "" )
    nora_global_set( "Nora.Projects.${NAME}.Path" "${CMAKE_CURRENT_LIST_DIR}" )

    # Create preprocessor name
    string( REPLACE "." "_" SAFE_DEFINE "${NAME}" )
    string( TOUPPER "${SAFE_DEFINE}" SAFE_DEFINE )
    nora_global_set( "Nora.Projects.${NAME}.PreprocessorName" "${SAFE_DEFINE}" )

    # Create package
    nora_package_create( ${NAME} "Nora.Projects.${NAME}.Package" )
    nora_global_package_build_path_set( "${NORA_PATH_PIPELINE}/" )

    # Scoped global
    nora_global_set( "Nora.Projects.glocal" "Nora.Projects.${NAME}" )

    # Create project
    project( "${Nora.Projects.${NAME}.Name}" CXX )

    # Default flags
    nora_cxx_flags_set( Nora.Projects.${NAME}.CxxFlags Nora.Projects.${NAME}.CFlags Nora.Projects.${NAME}.LinkerFlags ${CMAKE_BUILD_TYPE} )

    # get platform include path
    # nora_platform_includepath( PlatformIncludePath )

    # all projects are defaulted to /Include/ & /Include<PLATFORM>/
    if( EXISTS "${CMAKE_CURRENT_LIST_DIR}/Include" )
        nora_project_directory_include_add( Include )
    endif()

    # Includes for platform-specific configuration. On some Linux environments
    # the platform include path comes back empty, and because the test is for
    # 'path/' an empty value reads as true even with no such folder, hence the
    # explicit emptiness check.
    if( NOT "${PlatformIncludePath}" STREQUAL "" AND EXISTS "${CMAKE_CURRENT_LIST_DIR}/${PlatformIncludePath}" )
        nora_project_directory_include_add( "${PlatformIncludePath}" )
    endif()

    # all projects are defaulted to /Pipeline/
    nora_project_directory_link_add( ${NORA_PATH_PIPELINE} )

    # Default dll import
    nora_project_definitions_add( NORA_EXPORT_${Nora.Projects.${NAME}.PreprocessorName}=${Nora.Cxx.DLLImport} )
    nora_project_definitions_add( "NORA_C_EXPORT_${Nora.Projects.${NAME}.PreprocessorName}=extern \"C\" ${Nora.Cxx.DLLImport}" )
endfunction()

function( nora_project_test_create PROJECT )
    nora_project_create( ${PROJECT}.Test )
    nora_project_dependency_add( ${PROJECT} )
    nora_project_files_source_add_all( ${ARGN} )
    nora_project_install( EXEC )
endfunction()

# Set a named attribute on the current project.
#
# This passed no value at all, so the attribute was always set to the empty
# string and every 'if( ${...}.AttrSomething )' testing one was false. ARGN
# now carries the value, and an attribute named with no value is treated as a
# flag being turned on, which is how a bare nora_project_attribute_set( Foo )
# in an existing CMakeLists.txt reads.
function( nora_project_attribute_set NAME )
    if( "${ARGN}" STREQUAL "" )
        nora_global_set( "${Nora.Projects.glocal}.Attr${NAME}" ON )
    else()
        nora_global_set( "${Nora.Projects.glocal}.Attr${NAME}" ${ARGN} )
    endif()
endfunction()

function( nora_project_build_mode_set MODE )
    # Default flags
    nora_cxx_flags_set( ${Nora.Projects.glocal}.CxxFlags ${Nora.Projects.glocal}.CFlags ${Nora.Projects.glocal}.LinkerFlags ${MODE} )
endfunction()

# add define
function( nora_project_definitions_add )
    nora_package_definitions_add( ${ARGN} )
endfunction()

# Set build name
function( nora_project_build_name_set NAME )
    nora_global_set( "${Nora.Projects.glocal}.InstallName" "${NAME}" )
endfunction()

# add include directories
function( nora_project_directory_include_add )
    nora_package_directory_include_add( ${ARGN} )
endfunction()

# Glob all paths under the specified include directory.

macro( nora_project_directory_subdirectory_list result curdir )
    #file(GLOB children RELATIVE ${curdir} ${curdir}/*)
    #file( GLOB Files ${curdir}/* )
    # nora_loginfo( "Recurse resolver - Globbing children ${children}." )

    # The list must be all absolute. A relative argument such as 'src' is
    # resolved against the CMakeLists.txt being processed, which is what
    # file( GLOB ) already does with it, so the globbed children come back
    # absolute; the root appended at the end has to be made absolute to match,
    # or it is left to resolve against whatever the consumer assumes.
    get_filename_component( curdir_absolute "${curdir}" ABSOLUTE BASE_DIR "${CMAKE_CURRENT_SOURCE_DIR}" )

    file( GLOB children ${curdir_absolute}/* )
    set( dirlist "" )
    foreach( child ${children} )
        nora_log_event_project( "Recurse resolver - Found child ${child}." )

        # This tested 'EXISTS ${File}/CMakeLists.txt'. File is not a variable of
        # this macro -- the condition was copied from nora_directory_add_all,
        # whose loop variable is File -- and a macro shares its caller's scope,
        # so it read whatever File happened to hold. Reached through
        # nora_directory_add_all it was the project directory, which always has
        # a CMakeLists.txt, so the test passed by accident; reached any other
        # way it was empty and every subdirectory was discarded.
        #
        # The requirement is wrong regardless. These are source subdirectories
        # inside one project, and not having a CMakeLists.txt in each of them is
        # the entire point of Nora. Any directory that is not hidden belongs in
        # the resolver set.
        if( IS_DIRECTORY ${child} AND NOT ${child} MATCHES "^${CMAKE_SOURCE_DIR}/\\." )
            nora_log_event_project( "\tRegistering directory with resolver set." )
            list( APPEND dirlist ${child} )
        else()
            nora_log_event_project( "\tNot a directory, so leaving it out." )
        endif()
    endforeach()

    # Append our root.
    list( APPEND dirlist ${curdir_absolute} )

    set( ${result} ${dirlist} )
endmacro()

# For projects where we still want recurse resolve, but
# source is in different folders.
function( nora_project_files_include_add_all )
    nora_project_directory_subdirectory_list( subdirs ${ARGN} )

    # The resolver yields absolute directories. These used to be prefixed with
    # the project directory again, giving '<project>/<absolute path>', so only
    # the project and its named source folder ever became usable include roots:
    # '#include "alpha/a.h"' worked while '#include "a.h"' did not, even though
    # registering each subdirectory is what the resolver is for.
    # nora_path_prefix now leaves an absolute entry alone.
    foreach( subdir ${subdirs} )
        nora_project_directory_include_add( ${subdir} )
    endforeach()
endfunction()

function( nora_project_directory_add_source_any )
    nora_log_info( "[Resolver] Running on path ${ARGN}" )
    nora_project_directory_subdirectory_list( subdirs ${ARGN} )
    foreach( subdir ${subdirs} )
        nora_log_info( "[Resolver] Found subdirectory ${subdir}" )
        nora_project_files_source_add_all( ${subdir} )
    endforeach()
endfunction()

# Resolve all subs for projects where source and include
# are in same folder.
function( nora_project_directory_add_any )
    nora_log_event_project( "Recurse resolver - Requested resolve at root directory ${ARGN}." )
    nora_project_directory_subdirectory_list( subdirs ${ARGN} )

    nora_log_event_project( "\tRegistering resolver set with project." )
    foreach( subdir ${subdirs} )
        nora_log_event_project( "\t\tRegistering ${subdir} to project." )
        nora_project_files_include_add_all( ${subdir} )
        nora_project_directory_add_source_any( ${subdir} )
    endforeach()
endfunction()

# add extern include directories
function( nora_project_directory_external_include_add_any )
    nora_package_directory_include_external_add( ${ARGN} )
endfunction()

# add extern links
function( nora_project_external_link_add )
    nora_package_link_external_add( ${ARGN} )
endfunction()

# add extern binaries
function( nora_project_external_binary_add )
    nora_package_binary_external_add( ${ARGN} )
endfunction()

# add library directories
function( nora_project_directory_link_add )
    nora_package_directory_link_add( ${ARGN} )
endfunction()

# add links
function( nora_project_link_add )
    nora_package_link_add_many( ${ARGN} )
endfunction()

# Set sources
function( nora_project_source_set )
    # To absolute
    nora_path_prefix( "${ARGN}" Absolute "${CMAKE_CURRENT_LIST_DIR}/" )

    # add
    nora_global_set( "${Nora.Projects.glocal}.Sources" "${${Nora.Projects.glocal}.Sources};${Absolute}" )
endfunction()

# Set project output path
function( nora_global_project_path_build PATH )
    # Path must end with \/
    if( NOT "${PATH}" MATCHES "[\\\\\\/]$" )
        set( PATH "${PATH}/" )
    endif()

    # IS_ABSOLUTE is somewhat unreliable
    #
    # The drive-letter class read [A-z], which is not the letters: between Z
    # and a that range also covers [ \ ] ^ _ and the backtick, so paths such
    # as '^:/x' were treated as absolute. [A-Za-z] is what was meant.
    if( "${PATH}" MATCHES "^[A-Za-z]:[\\\\\\/]|^[\\\\\\/]" )
        nora_global_package_build_path_set( "${PATH}${CMAKE_BUILD_TYPE}/" )
    else()
        nora_global_package_build_path_set( "${${Nora.Projects.glocal}.Path}/${PATH}${CMAKE_BUILD_TYPE}/" )
    endif()

    if( NOT EXISTS "${${Nora.Packages.glocal}.BuildPath}" )
        nora_log_info( "Created output directory ${${Nora.Packages.glocal}.BuildPath}" )
        file( MAKE_DIRECTORY "${${Nora.Packages.glocal}.BuildPath}" )
    endif()
endfunction()

# Set sources by searching inside directories given
# Can specify platform specific by:
# WINDOWS Path1 Path2 PathN
function( nora_project_files_source_add_all )
    # Parse arguments
    cmake_parse_arguments( ARG "" "" "${Nora.Platforms.Uppercase}" ${ARGN} )

    nora_log_info( "Source search requested for project ${Nora.Projects.glocal}" )

    # Compose folders
    set( Folders ${ARG_UNPARSED_ARGUMENTS} )
    foreach( Platform ${Nora.Platforms.Uppercase} )
        if( ${Platform} STREQUAL ${Nora.Platform.Uppercase} )
            list( APPEND Folders ${ARG_${Platform}} )
        endif()
    endforeach()

    # To absolute
    nora_path_prefix( "${Folders}" AbsoluteFolders "${CMAKE_CURRENT_LIST_DIR}/" )

    nora_log_info( "Source folders: ${Folders} -> ${AbsoluteFolders}" )

    # Apply
    nora_postfix( "${AbsoluteFolders}" Headers "/*.h" )
    nora_postfix( "${AbsoluteFolders}" Sources "/*.cpp" )
    nora_postfix( "${AbsoluteFolders}" Asm "/*.asm" )
    nora_postfix( "${AbsoluteFolders}" AsmS "/*.S" )
    file( GLOB_RECURSE SOURCES ${Headers} ${Sources} ${Asm} ${AsmS} )
    nora_global_set( "${Nora.Projects.glocal}.Sources" "${${Nora.Projects.glocal}.Sources};${SOURCES}" )
    nora_log_info( "Sources for ${Nora.Projects.glocal}: ${${Nora.Projects.glocal}.Sources}" )
endfunction()

function( nora_project_load_order MODE )
    nora_package_load_order( ${MODE} ${ARGN} )
endfunction()

# add project dependencies
function( nora_project_dependency_add )
    nora_package_dependency_add( ${ARGN} )
endfunction()

# Install project
# Options:
#   VIRTUAL : Does not produce an output and is instead handled internally
#   DYNAMIC : Produces a dynamic linked library
#   STATIC  : Produces a statically linked library
#   EXEC    : Executable
function( nora_project_install )
    nora_global_set( ${Nora.Projects.glocal}.InstallType ${ARGN} )

    # Set installed
    if( NOT "${ARGN}" STREQUAL "VIRTUAL" )
        nora_global_package_installed_set( "${${Nora.Projects.glocal}.Name}" "${ARGN}" )
    endif()
endfunction()

# Set project description
function( nora_global_project_description DESC )
    nora_global_package_description_set( ${DESC} )
endfunction()