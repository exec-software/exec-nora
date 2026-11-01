# Copyright (C) 2008 - 2026 Execute Software.  All rights reserved.
# SPDX-License-Identifier: MIT

# Find the directory that holds resolved package configuration, by walking up
# from FULL_PATH looking for a 'code/vendor'. Writes the answer into OUT.
#
# A workspace without a code/vendor could not configure at all. Three things
# went wrong together:
#
#   - The recursive call passed ${NEW_PATH} unquoted. Walking up from '/foo'
#     produces an empty string, so the macro was invoked with two arguments
#     instead of three: "Macro invoked with incorrect arguments".
#   - The branch that gives up created a .packages directory but never set
#     OUT, so the caller's variable stayed empty, PackageDir became empty, and
#     the package wrote itself to '/<Name>.<Type>.pck' -- which fails with
#     permission denied, as the last error of a confusing pile.
#   - The depth guard called return() from inside a macro. A macro has no
#     scope of its own, so that returns from the calling FUNCTION, abandoning
#     nora_package_create halfway through initialising the package.
#
# So: the search always produces a usable directory, and the fallback is a
# .packages directory inside the build tree.
macro( nora_package_output_search FULL_PATH COUNT OUT )
    if( EXISTS "${FULL_PATH}/code/vendor" )
        set( ${OUT} "${FULL_PATH}/code/vendor" )
    elseif( "${FULL_PATH}" STREQUAL "" OR ${COUNT} GREATER_EQUAL 24 )
        set( ${OUT} "${NORA_PATH_BUILD_CMAKE_CACHE}/.packages" )
        file( MAKE_DIRECTORY "${${OUT}}" )
    else()
        string( FIND "${FULL_PATH}" "/" _INDEX REVERSE )
        if( _INDEX EQUAL -1 )
            set( ${OUT} "${NORA_PATH_BUILD_CMAKE_CACHE}/.packages" )
            file( MAKE_DIRECTORY "${${OUT}}" )
        else()
            string( SUBSTRING "${FULL_PATH}" 0 ${_INDEX} NEW_PATH )
            math( EXPR NEW_COUNT "${COUNT} + 1" )
            nora_package_output_search( "${NEW_PATH}" ${NEW_COUNT} ${OUT} )
        endif()
    endif()
endmacro()

# Create package
# @Name: Name of the package
function( nora_package_create NAME OUT )
    # Must not exist
    if( NOT "${Nora.Packages.${NAME}.Name}" STREQUAL "" )
        nora_log_error( "Package with name '${NAME}' already exists" )
    endif()

    # append
    list( APPEND Nora.Packages ${NAME} )
    nora_global_set( Nora.Packages "${Nora.Packages}" )

    # Find .Package directory
    nora_package_output_search( "${CMAKE_CURRENT_LIST_DIR}" 0 DIR )

    # Initialize variables
    nora_global_set( "Nora.Packages.${NAME}.Name" "${NAME}" )
    nora_global_set( "Nora.Packages.${NAME}.Dir" "${CMAKE_CURRENT_LIST_DIR}" )
    nora_global_set( "Nora.Packages.${NAME}.IncludeDirs" "" )
    nora_global_set( "Nora.Packages.${NAME}.ExternIncludeDirs" "" )
    nora_global_set( "Nora.Packages.${NAME}.Dependencies" "" )
    nora_global_set( "Nora.Packages.${NAME}.AllDependencies" "" )
    nora_global_set( "Nora.Packages.${NAME}.LinkDirs" "" )
    nora_global_set( "Nora.Packages.${NAME}.Links" "" )
    nora_global_set( "Nora.Packages.${NAME}.ExternLinks" "" )
    nora_global_set( "Nora.Packages.${NAME}.ExternBinaries" "" )
    nora_global_set( "Nora.Packages.${NAME}.Sources" "" )
    nora_global_set( "Nora.Packages.${NAME}.Installed" "" )
    nora_global_set( "Nora.Packages.${NAME}.InstalledType" "" )
    nora_global_set( "Nora.Packages.${NAME}.Defines" "" )
    nora_global_set( "Nora.Packages.${NAME}.LoadBefore" "" )
    nora_global_set( "Nora.Packages.${NAME}.LoadAfter" "" )
    nora_global_set( "Nora.Packages.${NAME}.Desc" "<No description supplied>" )
    nora_global_set( "Nora.Packages.${NAME}.PackageDir" "${DIR}" )
    # '.packages' is what scripts/install.sh creates and what the search above
    # creates when it finds nowhere better. This line asked for '.Packages',
    # so on a case-sensitive filesystem the workspace-level search path never
    # matched the directory that exists, and a package could only ever be found
    # through the discovered vendor directory. On Windows it matched by
    # accident, which is why it held for so long.
    nora_global_set( "Nora.Packages.${NAME}.SearchPaths" "${NORA_ROOT}/.packages" "${DIR}" )
    nora_global_set( "Nora.Packages.${NAME}.BuildPath" "" )

    # Scoped global
    nora_global_set( "Nora.Packages.glocal" "Nora.Packages.${NAME}" )

    # Out?
    if( NOT "${OUT}" STREQUAL "" )
        nora_global_set( ${OUT} "Nora.Packages.${NAME}" )
    endif()
endfunction()

# add load orders
function( nora_package_load_order MODE )
    if( "${MODE}" STREQUAL "AFTER" )
        list( APPEND ${Nora.Packages.glocal}.LoadAfter ${ARGN} )
        nora_global_set( ${Nora.Packages.glocal}.LoadAfter ${${Nora.Packages.glocal}.LoadAfter} )
    elseif( "${MODE}" STREQUAL "BEFORE" )
        list( APPEND ${Nora.Packages.glocal}.LoadBefore ${ARGN} )
        nora_global_set( ${Nora.Packages.glocal}.LoadBefore ${${Nora.Packages.glocal}.LoadBefore} )
    else()
        nora_log_error( "Invalid load order mode, must be either AFTER or BEFORE" )
    endif()
endfunction()

# add include directories
function( nora_package_directory_include_add )
    list( GET ARGN 0 OptionalOption )
    if( NOT "${OptionalOption}" STREQUAL "GLOBAL" )
        nora_path_prefix( "${ARGN}" Dirs "${CMAKE_CURRENT_LIST_DIR}/" )
    else()
        list( REMOVE_AT ARGN 0 )
        set( Dirs ${ARGN} )
    endif()
    list( APPEND ${Nora.Packages.glocal}.IncludeDirs ${Dirs} )
    nora_global_set( ${Nora.Packages.glocal}.IncludeDirs ${${Nora.Packages.glocal}.IncludeDirs} )
endfunction()

# add extern include directories
function( nora_package_directory_include_external_add )
    list( GET ARGN 0 OptionalOption )
    if( NOT "${OptionalOption}" STREQUAL "GLOBAL" )
        nora_path_prefix( "${ARGN}" Dirs "${CMAKE_CURRENT_LIST_DIR}/" )
    else()
        list( REMOVE_AT ARGN 0 )
        set( Dirs ${ARGN} )
    endif()
    list( APPEND ${Nora.Packages.glocal}.ExternIncludeDirs ${Dirs} )
    nora_global_set( ${Nora.Packages.glocal}.ExternIncludeDirs ${${Nora.Packages.glocal}.ExternIncludeDirs} )
endfunction()

# add extern include directories
function( nora_package_link_external_add )
    list( APPEND ${Nora.Packages.glocal}.ExternLinks ${ARGN} )
    nora_global_set( ${Nora.Packages.glocal}.ExternLinks ${${Nora.Packages.glocal}.ExternLinks} )
endfunction()

# add extern binaries
function( nora_package_binary_external_add )
    list( APPEND ${Nora.Packages.glocal}.ExternBinaries ${ARGN} )
    nora_global_set( ${Nora.Packages.glocal}.ExternBinaries ${${Nora.Packages.glocal}.ExternBinaries} )
endfunction()

# add define
function( nora_package_definitions_add )
    list( APPEND ${Nora.Packages.glocal}.Defines ${ARGN} )
    nora_global_set( ${Nora.Packages.glocal}.Defines ${${Nora.Packages.glocal}.Defines} )
endfunction()

# add library directories
function( nora_package_directory_link_add )
    list( APPEND ${Nora.Packages.glocal}.LinkDirs ${ARGN} )
    nora_global_set( ${Nora.Packages.glocal}.LinkDirs ${${Nora.Packages.glocal}.LinkDirs} )
endfunction()

# add package dependencies
function( nora_package_dependency_add )
    list( APPEND ${Nora.Packages.glocal}.Dependencies ${ARGN} )
    nora_global_set( ${Nora.Packages.glocal}.Dependencies ${${Nora.Packages.glocal}.Dependencies} )
endfunction()

# add links
function( nora_package_link_add_many )
    list( APPEND ${Nora.Packages.glocal}.Links ${ARGN} )
    nora_global_set( ${Nora.Packages.glocal}.Links ${${Nora.Packages.glocal}.Links} )
endfunction()

# add installed
function( nora_global_package_installed_set Installed Type )
    nora_global_set( ${Nora.Packages.glocal}.Installed ${Installed} )
    nora_global_set( ${Nora.Packages.glocal}.InstalledType ${Type} )
endfunction()

# Set description
function( nora_global_package_description_set DESC )
    nora_global_set( ${Nora.Packages.glocal}.Desc "${DESC}" )
endfunction()

# Set build path
function( nora_global_package_build_path_set PATH )
    nora_global_set( ${Nora.Packages.glocal}.BuildPath "${PATH}" )
endfunction()

# Finalize package
function( nora_package_finalize )
    foreach( Package ${Nora.Packages} )
        # Sanitize definitions
        string( REPLACE "\"" "\\\"" Defines "${Nora.Packages.${Package}.Defines}" )

        # write config
        nora_configuration_write_start( Config )
        nora_configuration_write( Config Name ${Nora.Packages.${Package}.Name} )
        nora_configuration_write( Config Dir ${Nora.Packages.${Package}.Dir} )
        nora_configuration_write( Config IncludeDirs ${Nora.Packages.${Package}.IncludeDirs} )
        nora_configuration_write( Config ExternIncludeDirs ${Nora.Packages.${Package}.ExternIncludeDirs} )
        nora_configuration_write( Config Dependencies ${Nora.Packages.${Package}.Dependencies} )
        nora_configuration_write( Config LinkDirs ${Nora.Packages.${Package}.LinkDirs} )
        nora_configuration_write( Config Links ${Nora.Packages.${Package}.Links} )
        nora_configuration_write( Config ExternLinks ${Nora.Packages.${Package}.ExternLinks} )
        nora_configuration_write( Config ExternBinaries ${Nora.Packages.${Package}.ExternBinaries} )
        nora_configuration_write( Config Sources ${Nora.Packages.${Package}.Sources} )
        nora_configuration_write( Config Installed ${Nora.Packages.${Package}.Installed} )
        nora_configuration_write( Config InstalledType ${Nora.Packages.${Package}.InstalledType} )
        nora_configuration_write( Config Defines ${Nora.Packages.${Package}.Defines} )
        nora_configuration_write( Config LoadBefore ${Nora.Packages.${Package}.LoadBefore} )
        nora_configuration_write( Config LoadAfter ${Nora.Packages.${Package}.LoadAfter} )
        nora_configuration_write( Config Desc ${Nora.Packages.${Package}.Desc} )
        nora_configuration_write( Config SearchPaths ${Nora.Packages.${Package}.SearchPaths} )
        nora_configuration_write( Config BuildPath ${Nora.Packages.${Package}.BuildPath} )
        nora_configuration_write_end( Config "${Nora.Packages.${Package}.PackageDir}/${Nora.Packages.${Package}.Name}.${CMAKE_BUILD_TYPE}.pck" )
    endforeach()
endfunction()
