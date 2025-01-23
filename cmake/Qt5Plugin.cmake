# This file contains the minimal code to compile a shared Qt plugin with CMake.
# It's based on qt6_add_plugin from Qt6 with all code not related to shared
# plugins (module libraries) removed. Internal functions have the prefix
# _qt_wrap instead of _qt.

function(_qt_wrap_internal_apply_shared_win_prefix_and_suffix target)
    if(WIN32 AND NOT MSVC)
            set_property(TARGET "${target}" PROPERTY IMPORT_SUFFIX ".a")
            set_property(TARGET "${target}" PROPERTY PREFIX "")
            set_property(TARGET "${target}" PROPERTY IMPORT_PREFIX "lib")
    endif()
endfunction()

function(_qt_wrap_internal_set_up_static_runtime_library target)
    if(QT_FEATURE_static_runtime)
        if(MSVC)
            set_property(TARGET ${target} PROPERTY
                MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")
        elseif(MINGW)
            get_target_property(target_type ${target} TYPE)
            if(target_type STREQUAL "EXECUTABLE")
                set(link_option PRIVATE)
            else()
                set(link_option INTERFACE)
            endif()
            if(CLANG)
                target_link_options(${target} ${link_option} "LINKER:-Bstatic")
            else()
                target_link_options(${target} ${link_option} "-static")
            endif()
        endif()
    endif()
endfunction()

function(qt5_add_plugin target)
    cmake_parse_arguments(PARSE_ARGV 1 arg "SHARED" "" "")

    if(NOT arg_SHARED)
        message(FATAL_ERROR "Only shared plugins can be built")
    endif()

    add_library(${target} MODULE ${arg_UNPARSED_ARGUMENTS})
    _qt_wrap_internal_set_up_static_runtime_library(${target})
    _qt_wrap_internal_apply_shared_win_prefix_and_suffix("${target}")

    if(APPLE)
        # CMake defaults to using .so extensions for loadable modules, aka plugins,
        # but Qt plugins are actually suffixed with .dylib.
        set_property(TARGET "${target}" PROPERTY SUFFIX ".dylib")
    endif()

    if(ANDROID)
        set_property(TARGET "${target}" PROPERTY SUFFIX "_${CMAKE_ANDROID_ARCH_ABI}.so")
    endif()

    set_property(TARGET ${target} PROPERTY _qt_expects_finalization TRUE)

    set(output_name ${target})
    if (arg_OUTPUT_NAME)
        set(output_name ${arg_OUTPUT_NAME})
    endif()
    set_property(TARGET "${target}" PROPERTY OUTPUT_NAME "${output_name}")

    if (ANDROID)
        set_target_properties(${target}
            PROPERTIES
            LIBRARY_OUTPUT_NAME "plugins_${arg_PLUGIN_TYPE}_${output_name}"
        )
    endif()

    # Derive the class name from the target name if it's not explicitly specified.
    if (NOT arg_CLASS_NAME)
        set(plugin_class_name "${target}")
    else()
        set(plugin_class_name "${arg_CLASS_NAME}")
    endif()

    set_target_properties(${target} PROPERTIES QT_PLUGIN_CLASS_NAME "${plugin_class_name}")

    target_compile_definitions(${target} PRIVATE
        QT_PLUGIN
        QT_DEPRECATED_WARNINGS
    )

    if(NOT TARGET qt_wrap_internal_plugins)
        add_custom_target(qt_wrap_internal_plugins)
    endif()
    add_dependencies(qt_wrap_internal_plugins ${target})
endfunction()

function(qt_add_plugin)
    qt5_add_plugin(${ARGV})
endfunction()
