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
    find_program(QT_QMAKE_EXECUTABLE NAMES "qmake" "qmake-qt5" "qmake.exe")
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
