#!/bin/sh
git submodule update --init --depth 1 aseprite
cd aseprite
git submodule update --init --depth 1 \
	laf \
	src/flic \
	third_party/cityhash \
	third_party/fmt \
	third_party/harfbuzz \
	third_party/libpng \
	third_party/pixman \
	third_party/zlib
git submodule update --init --depth 1 --recursive \
	third_party/freetype2
