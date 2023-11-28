cmake_minimum_required(VERSION 3.19)

project(orca_project)

# options
option(BUILD_MACOS_UNIVERSAL "Build Universal Externals") # not supported (you're on your own! :-)
option(ENABLE_LTO "enable link-time / interprocedural optimization")
option(BUILD_STATIC "build static executable")

# use ccache if available
find_program(CCACHE_PROGRAM ccache)
if(CCACHE_PROGRAM)
    message(STATUS "Found ccache in ${CCACHE_PROGRAM}")
    set_property(GLOBAL PROPERTY RULE_LAUNCH_COMPILE "${CCACHE_PROGRAM}")
endif()

if (ENABLE_LTO_IPO)
    include(CheckIPOSupported)
    check_ipo_supported(RESULT ipo_lto_supported OUTPUT check_lto_ipo_error)
    if(ipo_lto_supported)
        set(CMAKE_INTERPROCEDURAL_OPTIMIZATION ON)
        message(STATUS "IPO / LTO enabled")
    else()
        message(STATUS "IPO / LTO not supported: <${check_lto_ipo_error}>")
    endif()
endif()

message(STATUS "CMAKE_SYSTEM_NAME: ${CMAKE_SYSTEM_NAME}")

if (CMAKE_SYSTEM_NAME STREQUAL "Darwin")
    if (${CMAKE_GENERATOR} MATCHES "Xcode")
            if (${XCODE_VERSION} VERSION_LESS 10)
                message(STATUS "Xcode 10 or higher is required. Please install from the Mac App Store.")
                return ()
            endif ()
    endif ()

    if (NOT CMAKE_OSX_ARCHITECTURES)
        if(BUILD_MACOS_UNIVERSAL)
            set(CMAKE_OSX_ARCHITECTURES "x86_64;arm64" CACHE STRING "macOS architecture" FORCE)
        else()
            set(CMAKE_OSX_ARCHITECTURES ${CMAKE_SYSTEM_PROCESSOR} CACHE STRING "macOS architecture" FORCE)
        endif()
        message("CMAKE_OSX_ARCHITECTURES set to ${CMAKE_OSX_ARCHITECTURES}")
    endif()

    # i.e check if homebrew is used, set local prefix accordingly
    set(local_prefix "/usr/local")
    execute_process(
        COMMAND brew --prefix
        OUTPUT_VARIABLE homebrew_prefix
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )
    if(DEFINED homebrew_prefix)
        set(HAS_HOMEBREW 1)
        set(local_prefix ${homebrew_prefix})
        execute_process(
            COMMAND brew --prefix portmidi
            OUTPUT_VARIABLE portmidi_prefix
            OUTPUT_STRIP_TRAILING_WHITESPACE
        )
        if(DEFINED portmidi_prefix)
            set(HAS_HOMEBREW_PORTMIDI)
        endif()
        execute_process(
            COMMAND brew --prefix ncurses
            OUTPUT_VARIABLE ncurses_prefix
            OUTPUT_STRIP_TRAILING_WHITESPACE
        )
        if(DEFINED ncurses_prefix)
            set(HAS_HOMEBREW_NCURSES)
        endif()
    endif()

endif()

# ------------------------------------------------------------------------------
# main

set(PROJECT_NAME orca)

set(PROJECT_SOURCES
    gbuffer.c
    field.c
    vmio.c
    sim.c
    # livecoding
    osc_out.c
    term_util.c
    sysmisc.c
    thirdparty/oso.c
    tui_main.c
)

set(THIRDPARTY_DIR
    ${CMAKE_SOURCE_DIR}/thirdparty
)

set(THIRDPARTY_SOURCES
    ${THIRDPARTY_DIR}/oso.c
)

if(BUILD_STATIC)
    set(portmidi_prefix ${CMAKE_BINARY_DIR}/deps)
endif()


add_executable(
    ${PROJECT_NAME}
    ${PROJECT_SOURCES}
    ${THIRDPARTY_SOURCES}
)

target_include_directories(
    ${PROJECT_NAME}
    PUBLIC
    ${THIRDPARTY_DIR}
    ${local_prefix}/include
    ${ncurses_prefix}/include
    ${portmidi_prefix}/include
)

target_compile_definitions(
    ${PROJECT_NAME}
    PUBLIC
    _XOPEN_SOURCE_EXTENDED=1
    $<$<PLATFORM_ID:Darwin>:ORCA_OS_MAC>
)

target_compile_options(
    ${PROJECT_NAME}
    PUBLIC
    "-isystem thirdparty"
)

target_link_directories(
    ${PROJECT_NAME}
    PUBLIC
    ${local_prefix}/lib
    ${ncurses_prefix}/lib
    ${portmidi_prefix}/lib
)

target_link_options(
    ${PROJECT_NAME}
    PUBLIC

)

target_link_libraries(
    ${PROJECT_NAME}
    PUBLIC
    # -lncursesw
    # -lformw
    $<IF:$<BOOL:${BUILD_STATIC}>,${ncurses_prefix}/lib/libncursesw.a,-lncursesw>
    $<IF:$<BOOL:${BUILD_STATIC}>,${ncurses_prefix}/lib/libformw.a,-lformw>
    $<IF:$<BOOL:${BUILD_STATIC}>,${portmidi_prefix}/lib/libportmidi.a,-lportmidi>
    # ${ncurses_prefix}/lib/libncursesw.a
    # ${ncurses_prefix}/lib/libformw.a
    # ${portmidi_prefix/lib/libportmidi.a}
    # -lportmidi
)
