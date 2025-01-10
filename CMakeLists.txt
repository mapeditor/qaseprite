cmake_minimum_required(VERSION 3.16)

project(qaseprite LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

find_package(QT NAMES Qt6 Qt5 REQUIRED COMPONENTS Gui)
find_package(Qt${QT_VERSION_MAJOR} REQUIRED COMPONENTS Gui)

set(ENABLE_ASEPRITE_EXE off)
set(ENABLE_NEWS         off)
set(ENABLE_UPDATER      off)
set(ENABLE_SCRIPTING    off)
set(ENABLE_WEBSOCKET    off)
set(ENABLE_WEBP         off)

add_subdirectory(aseprite EXCLUDE_FROM_ALL)

add_library(qaseprite SHARED
  qaseprite.cpp
  qaseprite.json
)

set_target_properties(qaseprite PROPERTIES AUTOMOC ON)
target_link_libraries(qaseprite
    PRIVATE Qt${QT_VERSION_MAJOR}::Gui
            laf-base
            dio-lib
            render-lib)

set(QT_INSTALL_PREFIX ${QT${QT_VERSION_MAJOR}_INSTALL_PREFIX})
set(QT_INSTALL_PLUGINS ${QT${QT_VERSION_MAJOR}_INSTALL_PLUGINS})

# If QT_INSTALL_PREFIX is empty, try to derive it from QT_DIR, cutting off the
# last three components ("lib/cmake/Qt5") from the path
if(NOT QT_INSTALL_PREFIX)
  set(QT_INSTALL_PREFIX ${QT_DIR})
  get_filename_component(QT_INSTALL_PREFIX ${QT_INSTALL_PREFIX} DIRECTORY)
  get_filename_component(QT_INSTALL_PREFIX ${QT_INSTALL_PREFIX} DIRECTORY)
  get_filename_component(QT_INSTALL_PREFIX ${QT_INSTALL_PREFIX} DIRECTORY)
endif()

# If QT_INSTALL_PLUGINS is empty, set it to "plugins"
if(NOT QT_INSTALL_PLUGINS)
  set(QT_INSTALL_PLUGINS "plugins")
endif()

install(
  TARGETS qaseprite
  LIBRARY DESTINATION "${QT_INSTALL_PREFIX}/${QT_INSTALL_PLUGINS}/imageformats")
