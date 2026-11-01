# Copyright (C) 2008 - 2026 Execute Software.  All rights reserved.
# SPDX-License-Identifier: MIT

# Resolve package
function( nora_package_resolve NAME )
    nora_global_set( Nora.Packages.${NAME}.AllDependencies ${Nora.Packages.${NAME}.Dependencies} )

    # Resolve package
    foreach( Package ${Nora.Packages.${NAME}.Dependencies} )
        # Exists?
        if( NOT Nora.Packages.${Package}.Name )
            nora_log_error( "Could not find package '${Package}', package may be corrupted" )
        endif()

        # add defines
        list( APPEND Nora.Packages.${NAME}.AllDependencies ${Nora.Packages.${Package}.AllDependencies} )
        list( REMOVE_DUPLICATES Nora.Packages.${NAME}.AllDependencies )
        nora_global_set( Nora.Packages.${NAME}.AllDependencies ${Nora.Packages.${NAME}.AllDependencies} )

        # add defines
        list( APPEND Nora.Packages.${NAME}.Defines ${Nora.Packages.${Package}.Defines} )
        list( REMOVE_DUPLICATES Nora.Packages.${NAME}.Defines )
        nora_global_set( Nora.Packages.${NAME}.Defines ${Nora.Packages.${NAME}.Defines} )

        # add include dirs
        list( APPEND Nora.Packages.${NAME}.IncludeDirs ${Nora.Packages.${Package}.IncludeDirs} )
        list( REMOVE_DUPLICATES Nora.Packages.${NAME}.IncludeDirs )
        nora_global_set( Nora.Packages.${NAME}.IncludeDirs ${Nora.Packages.${NAME}.IncludeDirs} )

        # add extern include dirs
        list( APPEND Nora.Packages.${NAME}.ExternIncludeDirs ${Nora.Packages.${Package}.ExternIncludeDirs} )
        list( REMOVE_DUPLICATES Nora.Packages.${NAME}.ExternIncludeDirs )
        nora_global_set( Nora.Packages.${NAME}.ExternIncludeDirs ${Nora.Packages.${NAME}.ExternIncludeDirs} )

        # add link dirs
        list( APPEND Nora.Packages.${NAME}.LinkDirs ${Nora.Packages.${Package}.LinkDirs} )
        list( REMOVE_DUPLICATES Nora.Packages.${NAME}.LinkDirs )
        nora_global_set( Nora.Packages.${NAME}.LinkDirs ${Nora.Packages.${NAME}.LinkDirs} )

        # add libs
        list( APPEND Nora.Packages.${NAME}.Links ${Nora.Packages.${Package}.Links} )
        if( NOT ${Nora.Packages.${Package}.InstalledType} STREQUAL "EXEC" )
            list( APPEND Nora.Packages.${NAME}.Links ${Nora.Packages.${Package}.Installed} )
        endif()
        list( REMOVE_DUPLICATES Nora.Packages.${NAME}.Links )
        nora_global_set( Nora.Packages.${NAME}.Links ${Nora.Packages.${NAME}.Links} )

        # add extern libs
        #list(APPEND Nora.package.${NAME}.ExternLinks ${Nora.package.${Package}.ExternLinks})
        #list(REMOVE_DUPLICATES Nora.package.${NAME}.ExternLinks)
        #Nora_SetGlobal(Nora.package.${NAME}.ExternLinks ${Nora.package.${NAME}.ExternLinks})

        # add extern binaries
        list( APPEND Nora.Packages.${NAME}.ExternBinaries ${Nora.Packages.${Package}.ExternBinaries} )
        list( REMOVE_DUPLICATES Nora.Packages.${NAME}.ExternBinaries )
        nora_global_set( Nora.Packages.${NAME}.ExternBinaries ${Nora.Packages.${NAME}.ExternBinaries} )
    endforeach()
endfunction()

# Resolver pass
macro( nora_package_resolver_pass PACKAGES OUT_DEPTH )
    unset( DidResolve )
    foreach( Package ${${PACKAGES}} )
        # foreach dependency
        unset( Invalid )
        foreach( Dep ${Nora.Packages.${Package}.Dependencies} )
            # Does primary list contain this dependency?
            list( FIND ${PACKAGES} ${Dep} Index )
            if( NOT Index EQUAL -1 )
                nora_log_info( "Unable to resolve dependency package ${Dep} -- package is invalid." )
                set( Invalid "ON" )
                break()
            endif()
        endforeach()

        # Invalid?
        if( Invalid )
            continue()
        endif()

        # Resolve this package
        nora_package_resolve( ${Package} )
        nora_log_info( "Resolved package: ${Package}" )
        set( DidResolve "ON" )

        # remove
        list( REMOVE_ITEM ${PACKAGES} ${Package} )
    endforeach()

    # Resolved any?
    if( NOT DidResolve )
        # No package resolved, must be either empty or circular dependency
        list( LENGTH ${PACKAGES} Length )
        if( NOT Length EQUAL 0 )
            nora_log_error( "Circular or invalid dependency detected" )
        endif()
    else()
        # Next pass
        math( EXPR ${OUT_DEPTH} "${${OUT_DEPTH}} + 1" )
        nora_package_resolver_pass( ${PACKAGES} ${OUT_DEPTH} )
    endif()
endmacro()

# Resolve all package
function( nora_package_resolve_all )
    nora_log_event( "Resolving packages..." )

    # Copy list
    set( Packages ${Nora.Packages} )

    # Resolve
    set( Depth 0 )
    nora_package_resolver_pass( Packages Depth )

    # ...
    nora_log_info( "Packages resolved, ${Depth} passes!" )
endfunction()

# Search all package
function( nora_package_resolve_search_all )
    nora_log_event( "Appending external packages [[${CMAKE_CURRENT_LIST_DIR}]]" )

    # While there are package to include
    set( _ResolvedAny ON )
    while( _ResolvedAny )
        unset( _ResolvedAny )

        set( Packages ${Nora.Packages} )

        # foreach packageSearchPaths
        foreach( Package ${Nora.Packages} )
            foreach( Dep ${Nora.Packages.${Package}.Dependencies} )

                list( FIND Packages ${Dep} Index )
                if( Index EQUAL -1 )
                    # Attempt to find dependency
                    unset( _PackagePath )
                    foreach( Path ${Nora.Packages.${Package}.SearchPaths} )
                        if( EXISTS "${Path}/${Dep}.${CMAKE_BUILD_TYPE}.pck" )
                            # read configuration
                            nora_configuration_read( "${Path}/${Dep}.${CMAKE_BUILD_TYPE}.pck" "Nora.Packages.${Dep}." ON )

                            # append
                            list( APPEND Packages ${Nora.Packages.${Dep}.Name} )
                            set( _PackagePath ${Path}/${Dep}.pck )
                            break()
                        endif()
                    endforeach()

                    # Found?
                    if( NOT _PackagePath )
                        nora_log_error( "Could not find package '${Dep}' requested by '${Package}', search paths: \"${Nora.Packages.${Package}.SearchPaths}\". Package may not be configured." )
                    endif()

                    # Load
                    nora_log_info( "External package found: ${Dep}" )
                    # include("${_PackagePath}/nora.core.debug.core")

                    # Flag
                    set( _ResolvedAny ON )
                endif()
            endforeach()
        endforeach()

        # Set
        nora_global_set( Nora.Packages "${Packages}" )
    endwhile()
endfunction()