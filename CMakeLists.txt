# qaseprite - A Qt image format plugin for loading Aseprite files
# Copyright (c) 2024-2025  Thorbjørn Lindeijer
#
# This is the CMakeLists.txt file for building qaseprite. Parts of it are
# based on the CMakeLists.txt files from the Aseprite project, adjusted
# to only build the necessary parts for the Qt plugin.

cmake_minimum_required(VERSION 3.16)

project(qaseprite LANGUAGES C CXX)

set(CMAKE_POSITION_INDEPENDENT_CODE ON)

# ------------------------------------
# Adapted from aseprite/CMakeLists.txt
# ------------------------------------

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF) # We use -std=c++17 instead of -std=gnu++17 in macOS
set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>DLL")

# TODO: Check if necessary
if(MSVC)
  set(CMAKE_C_FLAGS_DEBUG_INIT            "/D_DEBUG /MDd /Zi /Ob0 /Od /RTC1")
  set(CMAKE_C_FLAGS_MINSIZEREL_INIT       "/MD /O1 /Ob1 /D NDEBUG")
  set(CMAKE_C_FLAGS_RELEASE_INIT          "/MD /O2 /Ob2 /D NDEBUG")
  set(CMAKE_C_FLAGS_RELWITHDEBINFO_INIT   "/MD /Zi /O2 /Ob1 /D NDEBUG")
  set(CMAKE_CXX_FLAGS_DEBUG_INIT          "/D_DEBUG /MDd /Zi /Ob0 /Od /RTC1")
  set(CMAKE_CXX_FLAGS_MINSIZEREL_INIT     "/MD /O1 /Ob1 /D NDEBUG")
  set(CMAKE_CXX_FLAGS_RELEASE_INIT        "/MD /O2 /Ob2 /D NDEBUG")
  set(CMAKE_CXX_FLAGS_RELWITHDEBINFO_INIT "/MD /Zi /O2 /Ob1 /D NDEBUG")
endif()

# Check repository status
if(NOT EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/aseprite/laf/CMakeLists.txt" OR
   NOT EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/aseprite/third_party/cityhash/CMakeLists.txt")
  message(FATAL_ERROR
    "Your qaseprite repository looks incomplete. Please read the following "
    "instructions carefully:"
    "\n"
    "1) If you have downloaded qaseprite source using the "
    "\"Code > Download ZIP\" button from GitHub, you will not be able to "
    "compile qaseprite. You need to get the code with other methods (continue "
    "reading)."
    "\n"
    "2) You can correctly clone the GitHub repository with the "
    "\"--recursive\" argument:"
    "\n"
    "  git clone --recursive https://github.com/mapeditor/qaseprite.git"
    "\n"
    "3) If you have already cloned the repository and see this message, "
    "you still need to initialize submodules running the following command:"
    "\n"
    "  git submodule update --init --recursive"
    "\n"
    "4) Or if you want to download the full source code in a .zip file, "
    "go to the releases page and get the latest \"qaseprite-1.x-source.tar.gz\":"
    "\n"
    "  https://github.com/mapeditor/qaseprite/releases"
    "\n")
endif()

# This is required for KDE/Qt destop integration, which sets
# BUILD_SHARED_LIBS to TRUE by default
set(BUILD_SHARED_LIBS off)

######################################################################
# Options (these can be specified in cmake command line or modifying
# CMakeCache.txt)

option(USE_SHARED_ZLIB     "Use your installed copy of zlib" off)
option(USE_SHARED_LIBPNG   "Use your installed copy of libpng" off)
option(USE_SHARED_PIXMAN   "Use your installed copy of pixman" off)
option(USE_SHARED_FREETYPE "Use shared FreeType library" off)
option(USE_SHARED_HARFBUZZ "Use shared HarfBuzz library" off)
option(ENABLE_CCACHE       "Use CCache to improve recompilation speed (optional)" on)

find_package(QT NAMES Qt6 Qt5 REQUIRED COMPONENTS Gui)
find_package(Qt${QT_VERSION_MAJOR} REQUIRED COMPONENTS Gui)

set(LIBPNG_DIR          ${CMAKE_CURRENT_SOURCE_DIR}/aseprite/third_party/libpng)
set(PIXMAN_DIR          ${CMAKE_CURRENT_SOURCE_DIR}/aseprite/third_party/pixman)
set(FREETYPE_DIR        ${CMAKE_CURRENT_SOURCE_DIR}/aseprite/third_party/freetype2)
set(HARFBUZZ_DIR        ${CMAKE_CURRENT_SOURCE_DIR}/aseprite/third_party/harfbuzz)
set(ZLIB_DIR            ${CMAKE_CURRENT_SOURCE_DIR}/aseprite/third_party/zlib)

# Search in the "cmake" directory for additional CMake modules.
list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/aseprite/cmake)

if(ENABLE_CCACHE)
  find_package(CCache)
  if(CCache_FOUND)
    # Use e.g. "ccache clang++" instead of "clang++"
    set_property(GLOBAL PROPERTY RULE_LAUNCH_COMPILE "${CCache_EXECUTABLE}")
    set_property(GLOBAL PROPERTY RULE_LAUNCH_LINK    "${CCache_EXECUTABLE}")
  endif()
endif()

######################################################################
# Common definitions to compile all sources (app code and third party)

# Debug C/C++ flags
if(CMAKE_BUILD_TYPE STREQUAL Debug)
  add_definitions(-DDEBUGMODE -D_DEBUG)
else()
  add_definitions(-DNDEBUG)
endif()

# zlib
if(USE_SHARED_ZLIB)
  find_package(ZLIB REQUIRED)
else()
  set(ZLIB_FOUND ON)
  set(ZLIB_LIBRARY zlibstatic)
  set(ZLIB_LIBRARIES ${ZLIB_LIBRARY})
  set(ZLIB_INCLUDE_DIRS
    ${ZLIB_DIR}
    ${CMAKE_CURRENT_BINARY_DIR}/aseprite/third_party/zlib) # Zlib generated zconf.h file
  set(ZLIB_INCLUDE_DIR ${ZLIB_INCLUDE_DIRS} CACHE PATH "")
endif()
include_directories(${ZLIB_INCLUDE_DIRS})

# libpng
if(USE_SHARED_LIBPNG)
  find_package(PNG REQUIRED)
  add_definitions(${PNG_DEFINITIONS})
else()
  set(PNG_FOUND ON)
  set(PNG_LIBRARY png_static)
  set(PNG_LIBRARIES ${PNG_LIBRARY})
  set(PNG_INCLUDE_DIRS
    ${LIBPNG_DIR}
    ${CMAKE_CURRENT_BINARY_DIR}/aseprite/third_party/libpng) # Libpng generated pnglibconf.h file
  set(PNG_INCLUDE_DIR ${PNG_INCLUDE_DIRS} CACHE PATH "")
  set(PNG_PNG_INCLUDE_DIR ${PNG_INCLUDE_DIRS} CACHE PATH "")
endif()
include_directories(${PNG_INCLUDE_DIRS})
add_definitions(-DPNG_NO_MMX_CODE) # Do not use MMX optimizations in PNG code

# pixman
if(USE_SHARED_PIXMAN)
  find_library(PIXMAN_LIBRARY NAMES pixman pixman-1)
  find_path(PIXMAN_INCLUDE_DIR NAMES pixman.h PATH_SUFFIXES pixman-1)
else()
  set(PIXMAN_LIBRARY pixman)
  set(PIXMAN_INCLUDE_DIR
    ${PIXMAN_DIR}/pixman
    ${CMAKE_BINARY_DIR}) # For pixman-version.h
endif()
include_directories(${PIXMAN_INCLUDE_DIR})

# freetype
if(USE_SHARED_FREETYPE)
  find_package(Freetype REQUIRED)
else()
  set(FREETYPE_FOUND ON)
  set(FREETYPE_LIBRARY freetype)
  set(FREETYPE_LIBRARIES ${FREETYPE_LIBRARY})
  set(FREETYPE_INCLUDE_DIRS ${FREETYPE_DIR}/include)
endif()

# harfbuzz
if(USE_SHARED_HARFBUZZ)
  find_package(HarfBuzz)
else()
  set(HARFBUZZ_FOUND ON)
  set(HARFBUZZ_LIBRARIES harfbuzz)
  set(HARFBUZZ_INCLUDE_DIRS ${HARFBUZZ_DIR}/src)
endif()

# Third parties

# ------------------------------------------------
# Adapted from aseprite/third_party/CMakeLists.txt
# ------------------------------------------------

include_directories(aseprite/third_party)

if(MSVC)
  add_definitions(-D_CRT_SECURE_NO_WARNINGS)
endif(MSVC)

if(NOT USE_SHARED_ZLIB)
  set(SKIP_INSTALL_ALL on)
  # Don't build zlib tests
  set(ZLIB_BUILD_EXAMPLES OFF CACHE BOOL "Enable Zlib Examples")
  add_subdirectory(aseprite/third_party/zlib EXCLUDE_FROM_ALL)
endif()

if(NOT USE_SHARED_LIBPNG)
  set(SKIP_INSTALL_ALL ON)
  # We only need the static version of libpng
  set(PNG_SHARED OFF CACHE BOOL "Build shared lib")
  set(PNG_STATIC ON CACHE BOOL "Build static lib")
  set(PNG_TESTS OFF CACHE BOOL "Build libpng tests")
  add_subdirectory(aseprite/third_party/libpng EXCLUDE_FROM_ALL)
endif()

if(NOT USE_SHARED_PIXMAN)
  add_subdirectory(aseprite/third_party/pixman-cmake EXCLUDE_FROM_ALL)
endif()

if(NOT USE_SHARED_FREETYPE)
  set(SKIP_INSTALL_ALL on)
  set(WITH_BZip2 OFF CACHE BOOL "")

  add_subdirectory(aseprite/third_party/freetype2 EXCLUDE_FROM_ALL)

  target_compile_definitions(freetype PUBLIC
    FT_CONFIG_OPTION_SYSTEM_ZLIB)
  if(UNIX)
    target_include_directories(freetype BEFORE PUBLIC
      ${CMAKE_CURRENT_BINARY_DIR}/aseprite/third_party/freetype2/include)
  endif()

  if(HARFBUZZ_FOUND)
    target_link_libraries(freetype PRIVATE ${HARFBUZZ_LIBRARIES})
    target_include_directories(freetype PRIVATE ${HARFBUZZ_INCLUDE_DIRS})
  endif()

  if(NOT USE_SHARED_LIBPNG)
    add_dependencies(freetype ${PNG_LIBRARIES})
  endif()
endif()

if(NOT USE_SHARED_HARFBUZZ)
  if(NOT USE_SHARED_FREETYPE)
    set(ENV{FREETYPE_DIR} ${FREETYPE_DIR})
  endif()
  set(HB_HAVE_FREETYPE ON CACHE BOOL "Enable freetype interop helpers")
  set(HB_HAVE_GRAPHITE2 OFF CACHE BOOL "Enable Graphite2 complementary shaper")
  set(HB_BUILTIN_UCDN ON CACHE BOOL "Use HarfBuzz provided UCDN")
  set(HB_HAVE_GLIB OFF CACHE BOOL "Enable glib unicode functions")
  set(HB_HAVE_ICU OFF CACHE BOOL "Enable icu unicode functions")
  set(HB_HAVE_CORETEXT OFF CACHE BOOL "Enable CoreText shaper backend on macOS")
  set(HB_HAVE_UNISCRIBE OFF CACHE BOOL "Enable Uniscribe shaper backend on Windows")
  set(HB_HAVE_DIRECTWRITE OFF CACHE BOOL "Enable DirectWrite shaper backend on Windows")
  add_subdirectory(aseprite/third_party/harfbuzz EXCLUDE_FROM_ALL)
endif()

add_subdirectory(aseprite/third_party/fmt      EXCLUDE_FROM_ALL)

# cityhash
add_subdirectory(aseprite/third_party/cityhash EXCLUDE_FROM_ALL)

set(LAF_WITH_EXAMPLES   off)
set(LAF_WITH_TESTS      off)
set(LAF_WITH_CLIP       off)
set(LAF_BACKEND         "none")

add_subdirectory(aseprite/laf EXCLUDE_FROM_ALL)

# ----------------------------------------
# Adapted from aseprite/src/CMakeLists.txt
# ----------------------------------------

######################################################################
# Compiler-specific flags

if(UNIX)
  # All warnings except for switch cases with missing enum items
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -Wno-switch")

  # Prefer C++17 [[fallthrough]] attribute
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wimplicit-fallthrough")
endif()

if(NOT MSVC)
  # Disable warnings about signed/unsigned comparison.
  # TODO we should remove this (or move it to laf-base)
  add_definitions(-Wno-sign-compare)
endif()

######################################################################
# Aseprite Libraries (in preferred order to be built)

add_subdirectory(aseprite/src/doc       EXCLUDE_FROM_ALL)
add_subdirectory(aseprite/src/fixmath   EXCLUDE_FROM_ALL)
add_subdirectory(aseprite/src/flic      EXCLUDE_FROM_ALL)
add_subdirectory(aseprite/src/render    EXCLUDE_FROM_ALL)
add_subdirectory(aseprite/src/dio       EXCLUDE_FROM_ALL)

# ------------------------
# qaseprite specific setup
# ------------------------

add_library(qaseprite MODULE
  qaseprite.cpp
  qaseprite.json
)

set_target_properties(qaseprite PROPERTIES AUTOMOC ON)
target_link_libraries(qaseprite
    PRIVATE Qt${QT_VERSION_MAJOR}::Gui
            laf-base
            dio-lib
            render-lib)

set(QT_PLUGIN_PATH "" CACHE STRING "Install location for Qt plugins")

if(NOT QT_PLUGIN_PATH)
  set(QT_INSTALL_PREFIX ${QT${QT_VERSION_MAJOR}_INSTALL_PREFIX})
  set(QT_INSTALL_PLUGINS ${QT${QT_VERSION_MAJOR}_INSTALL_PLUGINS})

  if(DEFINED ENV{QT_PLUGIN_PATH})
    set(QT_PLUGIN_PATH $ENV{QT_PLUGIN_PATH})
  elseif(QT_INSTALL_PREFIX AND QT_INSTALL_PLUGINS)
    set(QT_PLUGIN_PATH "${QT_INSTALL_PREFIX}/${QT_INSTALL_PLUGINS}")
  else()
    if(NOT QT_QMAKE_EXECUTABLE)
      find_program(QT_QMAKE_EXECUTABLE NAMES "qmake" "qmake-qt5" "qmake.exe")
    endif()
    if(QT_QMAKE_EXECUTABLE)
      execute_process(COMMAND "${QT_QMAKE_EXECUTABLE}" "-query" "QT_INSTALL_PLUGINS"
                      OUTPUT_VARIABLE QT_PLUGIN_PATH
                      OUTPUT_STRIP_TRAILING_WHITESPACE)
    else()
      message(FATAL_ERROR "Cannot find qmake executable")
    endif()
  endif()
  set(QT_PLUGIN_PATH "${QT_PLUGIN_PATH}" CACHE STRING "Install location for Qt plugins" FORCE)
endif()

install(
  TARGETS qaseprite
  RUNTIME DESTINATION "${QT_PLUGIN_PATH}/imageformats"
  LIBRARY DESTINATION "${QT_PLUGIN_PATH}/imageformats")
