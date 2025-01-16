#!/bin/sh

show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --no-zlib         Skip updating the zlib submodule"
    echo "  --no-libpng       Skip updating the libpng submodule"
    echo "  --no-freetype     Skip updating the FreeType submodule"
    echo "  --no-harfbuzz     Skip updating the HarfBuzz submodule"
    echo "  --minimal         Apply all the --no-* options"
    echo "  --help            Show this help message"
}

# Default values for options
NO_ZLIB=false
NO_LIBPNG=false
NO_FREETYPE=false
NO_HARFBUZZ=false

# Parse command line arguments
for arg in "$@"; do
    case $arg in
        --no-zlib)
            NO_ZLIB=true
            ;;
        --no-libpng)
            NO_LIBPNG=true
            ;;
        --no-freetype)
            NO_FREETYPE=true
            ;;
        --no-harfbuzz)
            NO_HARFBUZZ=true
            ;;
        --minimal)
            NO_ZLIB=true
            NO_LIBPNG=true
            NO_FREETYPE=true
            NO_HARFBUZZ=true
            ;;
        --help)
            show_help
            exit 0
            ;;
        *)
            echo "Unknown option: $arg"
            show_help
            exit 1
            ;;
    esac
done

git submodule update --init --depth 1 aseprite
cd aseprite
git submodule update --init --depth 1 \
	laf \
	src/flic \
	third_party/cityhash \
	third_party/fmt \
	third_party/pixman

if [ "$NO_HARFBUZZ" = false ]; then
    git submodule update --init --depth 1 third_party/harfbuzz
fi

if [ "$NO_LIBPNG" = false ]; then
    git submodule update --init --depth 1 third_party/libpng
fi

if [ "$NO_ZLIB" = false ]; then
    git submodule update --init --depth 1 third_party/zlib
fi

if [ "$NO_FREETYPE" = false ]; then
    git submodule update --init --depth 1 --recursive third_party/freetype2
fi
