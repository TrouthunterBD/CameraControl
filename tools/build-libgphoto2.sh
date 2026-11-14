#!/bin/zsh
# Builds libgphoto2 from git (OM-1 Mark II support isn't in a release yet) into tools/.libgphoto2/.
# Homebrew's own libgphoto2 is left alone; tools/gphoto2 runs Homebrew's gphoto2 against this build.
# Needs: brew install gphoto2 autoconf automake libtool pkgconf gettext libexif libusb
set -e
here=${0:A:h}
rev=${1:-31a2f4089f19aec6caca7920b03e3eb7a251c5b6}  # pinned commit (full sha); pass another to update
src=$here/.libgphoto2/src
prefix=$here/.libgphoto2/install

rm -rf $here/.libgphoto2 && mkdir -p $src
git -C $src init -q
git -C $src fetch -q --depth 1 https://github.com/gphoto/libgphoto2.git $rev
git -C $src checkout -q FETCH_HEAD
echo "Building libgphoto2 $(git -C $src log -1 --format='%h %cd' --date=short)"

cd $src
export PATH="/opt/homebrew/opt/gettext/bin:$PATH"
autoreconf -is > ../autoreconf.log 2>&1
# --disable-nls: brew's build fails linking libintl; we don't need translations
# --with-camlibs=ptp2: only the driver the OM-1 uses
./configure --prefix=$prefix --disable-nls --with-camlibs=ptp2 \
  PKG_CONFIG_PATH=/opt/homebrew/lib/pkgconfig > ../configure.log 2>&1
make -j$(sysctl -n hw.ncpu) > ../make.log 2>&1
make install > ../install.log 2>&1
echo "Installed to $prefix"
