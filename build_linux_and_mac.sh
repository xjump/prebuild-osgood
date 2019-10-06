#!/usr/bin/env bash
set -e

WORKDIR=$(dirname $V8_DIR)
cd $WORKDIR

rm -rf $BUILD_DIR
mkdir -p $BUILD_DIR

git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
export PATH=$PATH:$WORKDIR/depot_tools

cd $WORKDIR
rm -rf v8
fetch v8

cd $WORKDIR/v8
git checkout $V8_VERSION
gclient sync
tools/dev/v8gen.py x64.release -- v8_monolithic=true v8_use_external_startup_data=false use_custom_libcxx=false

cd $V8_DIR/out.gn/x64.release
echo "starting build"
ninja 
rm -rf .git

###################################################################################
export RUST_BACKTRACE=full
curl https://sh.rustup.rs -sSf > rustup.sh && sh rustup.sh -y 
source $HOME/.cargo/env
export PATH=$PATH:$HOME/.cargo/bin
rustup component add rustfmt

# apt install build-essential pkg-config libc++-dev libc++abi-dev clang libclang-dev libssl-dev
# curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.34.0/install.sh | bash
# nvm install 12

cd $WORKDIR
git clone https://github.com/xjump/osgood.git
cd $WORKDIR/osgood
cd $WORKDIR/osgood/js
npm install 
npm audit fix
cd $WORKDIR/osgood
export CUSTOM_V8=$V8_DIR
cargo build --release -vv

rm -rf .git

cd $WORKDIR
sysOS=`uname -s`
zip -q -r prebuilt-$sysOS-$V8_VERSION.zip $WORKDIR/v8/include $WORKDIR/v8/out.gn $WORKDIR/osgood/target/release/osgood
mv prebuilt-$sysOS-$V8_VERSION.zip $BUILD_DIR

ls -al $BUILD_DIR
