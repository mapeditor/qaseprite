#!/bin/sh
VERSION=$1

if [ -z $VERSION ]
then
    echo "Usage: $0 <version>"
    exit 1
fi

# Make sure the submodules are up-to-date
./update-submodules.sh

# Create the source archive
git ls-files --recurse-submodules -z \
    | grep -z \
        -e '^[^/]*$' \
        -e '^aseprite/cmake/' \
        -e '^aseprite/laf/' \
        -e '^aseprite/src/dio/' \
        -e '^aseprite/src/doc/' \
        -e '^aseprite/src/fixmath/' \
        -e '^aseprite/src/flic/' \
        -e '^aseprite/src/render/' \
        -e '^aseprite/third_party/cityhash' \
        -e '^aseprite/third_party/fmt' \
        -e '^aseprite/third_party/freetype2' \
        -e '^aseprite/third_party/harfbuzz' \
        -e '^aseprite/third_party/libpng' \
        -e '^aseprite/third_party/pixman' \
        -e '^aseprite/third_party/zlib' \
    | grep -z --invert-match \
        -e '\.git' \
        -e '^aseprite/laf/clip/' \
        -e '^aseprite/laf/third_party/googletest/' \
        -e '^aseprite/third_party/harfbuzz/test/' \
        -e '^aseprite/third_party/libpng/contrib/' \
  | tar caf qaseprite-${VERSION}.tar.gz --xform s:^:qaseprite-${VERSION}/: --null -T-
