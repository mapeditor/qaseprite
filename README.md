# Qt Aseprite Image Plugin

This plugin adds support for reading `.ase` and `.aseprite` files images in Qt
applications.

Originally developed for [Tiled](https://github.com/mapeditor/tiled).

## How to Compile

### Git Checkout

We use Aseprite as a Git submodule. Make sure to update it recursively:

    git submodule update --init --recursive

> Not all of Aseprite is free software, but this plugin only uses MIT-licensed
> parts of Aseprite (dio, render and their dependencies doc, fixmath, flic,
> gfx and base).

### Install Dependencies

Install Qt. You can use the Qt Online Installer or any other method.

Install the [dependencies for Aseprite](https://github.com/aseprite/aseprite/blob/main/INSTALL.md).

### Configure CMake

In-source builds are disabled by Aseprite, so it is necessary to use a separate
build directory:

    cmake -B build -DCMAKE_BUILD_TYPE=Release

The Aseprite libraries used by this plugin rely on Zlib, Pixman, FreeType and
HarfBuzz. By default the versions from the Aseprite repository will be used,
but you can tell CMake to look for system versions instead by adding the
following parameters:

    -DUSE_SHARED_ZLIB=on \
    -DUSE_SHARED_LIBPNG=on \
    -DUSE_SHARED_PIXMAN=on \
    -DUSE_SHARED_FREETYPE=on \
    -DUSE_SHARED_HARFBUZZ=on

If you have Ninja installed, you can add `-G Ninja` to the CMake command line
for automatic parallel builds.

### Build and Install

Trigger the build:

    cmake --build build --config Release

The plugin will be built in the `build` directory. You can install it by
running:

    cmake --install build --config Release

This will install the plugin to the `plugins/imageformats` directory of the Qt
installation. You can also copy the plugin manually to the plugins directory of
your application.
