# Copyright (C) 2008 - 2026 Execute Software.  All rights reserved.
# SPDX-License-Identifier: MIT

# Configure all package
function( nora_project_configure_all )
    nora_log_event( "Configuring projects..." )

    # foreach project
    # CMake warns about target properties set before a target exists while this
    # loop runs; the loop below resolves them. This used to read
    # "!! Ignore Warnings !!", which told the reader to disregard everything
    # CMake said between here and there, real problems included.
    nora_log_info( "Configuring targets; property warnings in this section are resolved below." )
    foreach( Project ${Nora.Projects} )
        set( ArchiveDir "${${Nora.Projects.${Project}.Package}.BuildPath}" )
        set( LibraryDir "${${Nora.Projects.${Project}.Package}.BuildPath}" )
        set( RuntimeDir "${${Nora.Projects.${Project}.Package}.BuildPath}" )


        # Virtuals do not have installed
        if( NOT "${Nora.Projects.${Project}.InstallType}" STREQUAL "VIRTUAL" )

            # Find correct type and install final target
            if( "${Nora.Projects.${Project}.InstallType}" STREQUAL "DYNAMIC" )

                add_library( "${Nora.Projects.${Project}.Name}" SHARED ${Nora.Projects.${Project}.Sources} )

                # Output naming is left to CMake, which knows what the
                # platform expects: libfoo.so and libfoo.a on Linux, foo.dll
                # with a foo.lib import library on Windows.
                #
                # These four lines forced PREFIX "" and the Windows suffixes on
                # every platform, so a Linux build produced foo.dll and an ELF
                # executable called foo.exe. That was deliberate once: the
                # engine this grew out of was developed mainly on Windows and
                # its packing system wanted one filename everywhere, the way
                # Unreal does it. A general-purpose build system has no reason
                # to, and native names are what find_library, -lfoo, the
                # dynamic loader and every packaging tool already expect.
            elseif( "${Nora.Projects.${Project}.InstallType}" STREQUAL "STATIC" )
                add_library( "${Nora.Projects.${Project}.Name}" STATIC ${Nora.Projects.${Project}.Sources} )

                # Native naming; see the note on the dynamic branch above.
            elseif( "${Nora.Projects.${Project}.InstallType}" STREQUAL "EXEC" )
                add_executable( "${Nora.Projects.${Project}.Name}" ${Nora.Projects.${Project}.Sources} )

                # Native naming; see the note on the dynamic branch above.
                # On Linux this means no extension rather than a .exe on an ELF.

                # Custom name
                set( CustomName "Z_Mirror.${Nora.Projects.${Project}.Name}" )

                # Deduce actual dependencies. The loop that fills this is the
                # one below, which walks the same list; an empty foreach over
                # it stood here too and did nothing.
                set( ActualDependencies "" )

                # Prepare external binaries
                set( ExternBinaries ${${Nora.Projects.${Project}.Package}.ExternBinaries} )
                foreach( Dep ${${Nora.Projects.${Project}.Package}.AllDependencies} )
                    if( "${Nora.Packages.${Dep}.InstalledType}" STREQUAL "DYNAMIC" )
                        # Composed from the platform's own affixes rather than a
                        # literal ".dll", so this finds libDep.so on Linux and
                        # Dep.dll on Windows. A dependency resolved from a .pck
                        # is not a target in this build, so its filename has to
                        # be built rather than asked for.
                        list( APPEND ExternBinaries
                            "${Nora.Packages.${Dep}.BuildPath}${CMAKE_SHARED_LIBRARY_PREFIX}${Dep}${CMAKE_SHARED_LIBRARY_SUFFIX}" )
                    endif()

                    if( ${Dep} IN_LIST Nora.Projects )
                        list( APPEND ActualDependencies ${Dep} )
                    endif()
                endforeach()
                set( ExternBinaries "${ExternBinaries}" )
                string( REPLACE ";" " '" ExternBinaries "${ExternBinaries}" )

                # CMake is awkward about pasting a list into one argument, so the
                # list is re-joined by hand before it is handed to the script.
                if( NOT "${ActualDependencies}" STREQUAL "" )
                    add_custom_target(
                            "${CustomName}"
                            ALL COMMAND ${CMAKE_COMMAND} -DPROJECT="${Nora.Projects.${Project}.Path}" -DBINARIES="${ExternBinaries}" -DPIPELINE="${NORA_PATH_PIPELINE}" -DOUTPUT="${${Nora.Projects.${Project}.Package}.BuildPath}" -P "${NORA_PATH_BUILD}/toolchain/nora.toolchain.executable.post.cmake"
                            DEPENDS ${ActualDependencies}
                    )
                else()
                    add_custom_target(
                            "${CustomName}"
                            ALL COMMAND ${CMAKE_COMMAND} -DPROJECT="${Nora.Projects.${Project}.Path}" -DBINARIES="${ExternBinaries}" -DPIPELINE="${NORA_PATH_PIPELINE}" -DOUTPUT="${${Nora.Projects.${Project}.Package}.BuildPath}" -P "${NORA_PATH_BUILD}/toolchain/nora.toolchain.executable.post.cmake"
                    )
                endif()

                # Configure post processing dependencies
                add_dependencies( "${Nora.Projects.${Project}.Name}" "${CustomName}" )
            else()
                nora_log_error( "Could not install project ${Nora.Projects.${Project}.Name}, unknown option '${Nora.Projects.${Project}.InstallType}'" )
            endif()


            if( EXISTS "${Nora.Projects.${Project}.Path}/Runtime" )
                # Runtime virtual file system
                file( WRITE "${NORA_PATH_PIPELINE}/Runtime/${Project}.dvrf" "Runtime:${Nora.Projects.${Project}.Path}/Runtime" )
            endif()

            # Install name
            set_target_properties( ${Nora.Projects.${Project}.Name} PROPERTIES OUTPUT_NAME "${Nora.Projects.${Project}.InstallName}" )

            # Set flags
            #set_target_properties(
            #        "${Nora.Projects.${project}.Name}"
            #        PROPERTIES
            #        COMPILE_FLAGS "${Nora.Projects.${project}.CxxFlags} ${Nora.Projects.${project}.CFlags}"
            #        LINK_FLAGS "${Nora.Projects.${project}.LinkerFlags}"
            #)

            nora_log_info( "Setting target properties on ${Nora.Projects.${Project}.Name}" )
            set_target_properties( "${Nora.Projects.${Project}.Name}" PROPERTIES
                    CXX_STANDARD 17
                    CXX_STANDARD_REQUIRED YES
            )

            # Compile flags compile, link flags link.
            #
            # LinkerFlags and -Wl,--gc-sections were both passed as
            # COMPILE_FLAGS, where the compiler has no use for them, and the
            # only link-side call was target_link_libraries( ... INTERFACE ),
            # which describes what CONSUMERS of this target must link rather
            # than what this target links. Nothing consumes an executable, so
            # the flags reached no link line at all. The visible symptom was
            # the Verify build type: it compiled with -fsanitize=address and
            # then failed to link with undefined references to __asan_init,
            # because the sanitizer never made it to the linker.
            #
            # LINK_FLAGS rather than target_link_options, to stay within the
            # declared cmake_minimum_required of 3.7.
            set_target_properties( "${Nora.Projects.${Project}.Name}" PROPERTIES
                    COMPILE_FLAGS "${Nora.Projects.${Project}.CxxFlags} ${Nora.Projects.${Project}.CFlags}"
                    LINK_FLAGS "${Nora.Projects.${Project}.LinkerFlags} -Wl,--gc-sections"
            )

            #target_compile_options(
            #        "${Nora.Projects.${project}.Name}" PUBLIC
            #        ${Nora.Projects.${project}.CxxFlags}
            #        ${Nora.Projects.${project}.CFlags}
            #        ${Nora.Projects.${project}.LinkerFlags}
            #)

            # TODO: Experimental
            set_property( TARGET "${Nora.Projects.${Project}.Name}" PROPERTY LINK_DEPENDS_NO_SHARED 1 )

            # Configure destination
            set_target_properties(
                    "${Nora.Projects.${Project}.Name}"
                    PROPERTIES
                    ARCHIVE_OUTPUT_DIRECTORY "${ArchiveDir}"
                    LIBRARY_OUTPUT_DIRECTORY "${LibraryDir}"
                    RUNTIME_OUTPUT_DIRECTORY "${RuntimeDir}"
            )

            # ...
            nora_global_set( ${Nora.Projects.${Project}.Package}.AllDefines
                    NORA_API_${Nora.Projects.${Project}.PreprocessorName}

                    # Paths (Useful for build tools)
                    "NORA_PATH_PIPELINE=\"${NORA_PATH_PIPELINE}\""
                    "NORA_PATH_EXTERN=\"${NORA_PATH_EXTERN}\""
                    "NORA_PATH_BUILD=\"${NORA_PATH_BUILD}\""

                    # Internal export
                    "NORA_EXPORT=${Nora.Cxx.DLLExport}"
                    "NORA_IMPORT=${Nora.Cxx.DLLImport}"
                    "NORA_NOEXPORT=${Nora.Cxx.DLLIgnore}"
                    "NORA_EXPORT_${Nora.Projects.${Project}.PreprocessorName}=${Nora.Cxx.DLLExport}"
                    "NORA_C_EXPORT_${Nora.Projects.${Project}.PreprocessorName}=extern \"C\" ${Nora.Cxx.DLLExport}"

                    # Exception handling
                    "NORA_THROW=throw"

                    # platform Specific
                    ${Nora.Platform.${Nora.Platform}.Preprocessors}
                    NORA_PLATFORM_${Nora.Platform.Uppercase}

                    # compiler specific
                    NORA_COMPILER_${Nora.Compiler.Uppercase}
                    ${Nora.Compiler.Preprocessors}

                    # core
                    ${Nora.Cxx.Preprocessors}

                    # Defines
                    ${${Nora.Projects.${Project}.Package}.Defines}
                    )

            # remove duplicates
            set( IndexMap "" )
            set( DefineCopy "" )
            foreach( Define ${${Nora.Projects.${Project}.Package}.AllDefines} )
                string( FIND ${Define} "=" EQINDEX )
                if( NOT ${EQINDEX} EQUAL -1 )
                    string( SUBSTRING ${Define} 0 ${EQINDEX} DEFNAME )
                    if( NOT ${DEFNAME} IN_LIST IndexMap )
                        list( APPEND DefineCopy ${Define} )
                        list( APPEND IndexMap ${DEFNAME} )
                    endif()
                elseif( NOT ${Define} IN_LIST DefineCopy )
                    list( APPEND DefineCopy ${Define} )
                endif()
            endforeach()
            nora_global_set( ${Nora.Projects.${Project}.Package}.AllDefines ${DefineCopy} )

            # Preprocessors
            target_compile_definitions(
                    "${Nora.Projects.${Project}.Name}"

                    # Locals
                    PRIVATE ${${Nora.Projects.${Project}.Package}.AllDefines}
            )

        else()
            # Dummy target
            add_library( "${Nora.Projects.${Project}.Name}" INTERFACE )
            #add_custom_target("${Nora.Projects.${project}.Name}")
        endif()
    endforeach()
    nora_log_info( "Target configuration complete." )

    # foreach project
    foreach( Project ${Nora.Projects} )
        # Apply deps
        if( "${Nora.Projects.${Project}.InstallType}" STREQUAL "DYNAMIC" )
        else()
            foreach( Dep ${${Nora.Projects.${Project}.Package}.Dependencies} )
                # Is target?
                if( ${Dep} IN_LIST Nora.Projects )
                    add_dependencies( "${Nora.Projects.${Project}.Name}" "${Dep}" )
                endif()
            endforeach()
        endif()

        if( NOT "${Nora.Projects.${Project}.InstallType}" STREQUAL "VIRTUAL" )
            # Set linker language
            set_target_properties( "${Nora.Projects.${Project}.Name}" PROPERTIES LINKER_LANGUAGE CXX )

            # Apply
            if( NOT "${${Nora.Projects.${Project}.Package}.IncludeDirs}" STREQUAL "" )
                target_include_directories( "${Nora.Projects.${Project}.Name}" PUBLIC ${${Nora.Projects.${Project}.Package}.IncludeDirs} ${Nora.Projects.${Project}.Path} )
            endif()
            if( NOT "${${Nora.Projects.${Project}.Package}.ExternIncludeDirs}" STREQUAL "" )
                target_include_directories( "${Nora.Projects.${Project}.Name}" SYSTEM PUBLIC ${${Nora.Projects.${Project}.Package}.ExternIncludeDirs} )
            endif()
            if( NOT "${${Nora.Projects.${Project}.Package}.LinkDirs}" STREQUAL "" )
                # link_directories("${Nora.Projects.${project}.Name}" PUBLIC ${${Nora.Projects.${project}.Package}.LinkDirs})
            endif()
            if( NOT "${${Nora.Projects.${Project}.Package}.Links}" STREQUAL "" )
                set( Libs "" )
                foreach( DepLib ${${Nora.Projects.${Project}.Package}.Links} )
                    if( NOT ${DepLib} IN_LIST Nora.Projects )
                        find_library( ${DepLib}.FoundPath NAMES "${DepLib}" PATHS ${${Nora.Projects.${Project}.Package}.LinkDirs} )
                        if( ${DepLib}.FoundPath STREQUAL "${DepLib}.FoundPath-NOTFOUND" )
                            nora_log_error( "Project ${Project} failed to find library: '${DepLib}'\nAttempted to search in:\n${${Nora.Projects.${Project}.Package}.LinkDirs}" )
                        endif()
                        list( APPEND Libs ${${DepLib}.FoundPath} )
                    else()
                        # core resolves in house dependencies!
                        list( APPEND Libs ${DepLib} )
                    endif()
                endforeach()
                target_link_libraries( "${Nora.Projects.${Project}.Name}" PUBLIC ${Libs} )
                #target_link_libraries("${Nora.Projects.${project}.Name}" PUBLIC ${${Nora.Projects.${project}.Package}.Links})
            endif()
            if( NOT "${${Nora.Projects.${Project}.Package}.ExternLinks}" STREQUAL "" )
                target_link_libraries( "${Nora.Projects.${Project}.Name}" PUBLIC ${${Nora.Projects.${Project}.Package}.ExternLinks} )
            endif()

            # Additional links
            if( Nora.Platform STREQUAL Linux )
                target_link_libraries( "${Nora.Projects.${Project}.Name}" PUBLIC -ldl -pthread )
            endif()
        endif()

        # Create common file
        set( LocalProject Nora.Projects.${Project} )
        set( LocalPackage ${Nora.Projects.${Project}.Package} )
        set( TEMPLATE "" )
        # file(READ "${NORA_PATH_BUILD}/project/template/project.md" TMPL_PROJECTMD)
        include( ${NORA_PATH_BUILD}/project/template/nora.project.template.readme.cmake )
        # string(REPLACE "{NAME}" "${SAFE_DEFINE}" TMPL_PROJECTMD "${TMPL_PROJECTMD}")
        file( WRITE "${Nora.Projects.${Project}.Path}/${Nora.Projects.${Project}.Name}.config.md" "${TEMPLATE}" )

        # ...
        nora_log_info( "Configured project: ${Project}" )
    endforeach()

    # Build all project
    add_custom_target( "All" DEPENDS ${Nora.Projects} )

    # ...
    nora_log_info( "Projects configured!" )
endfunction()