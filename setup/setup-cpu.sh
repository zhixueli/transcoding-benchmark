#
# Script for compiling and installing FFmpeg from source on Amazon Linux 2 with support for both x86 and arm instances
#

# 1 - Update host OS

sudo yum update -y

# 2 - Install build dependencies & other packages

sudo yum install -y autoconf automake bzip2 bzip2-devel cmake freetype-devel gcc gcc-c++ git libtool make pkgconfig zlib-devel tmux zstd

# 3 - Create build directory

mkdir ~/ffmpeg_sources

# 4 - Compile the NASM assembler

cd ~/ffmpeg_sources
curl -O -L -k https://www.nasm.us/pub/nasm/releasebuilds/2.15.05/nasm-2.15.05.tar.bz2
tar xjvf nasm-2.15.05.tar.bz2
cd nasm-2.15.05
./autogen.sh
./configure --prefix="$HOME/ffmpeg_build" --bindir="$HOME/bin"
make
make install

# 5 - Compile the YASM assembler

cd ~/ffmpeg_sources
curl -O -L https://www.tortall.net/projects/yasm/releases/yasm-1.3.0.tar.gz
tar xzvf yasm-1.3.0.tar.gz
cd yasm-1.3.0
./configure --prefix="$HOME/ffmpeg_build" --bindir="$HOME/bin"
make
make install

# 6 - Compile x264

cd ~/ffmpeg_sources
git clone --depth 1 https://code.videolan.org/videolan/x264.git
cd x264
PKG_CONFIG_PATH="$HOME/ffmpeg_build/lib/pkgconfig" ./configure --prefix="$HOME/ffmpeg_build" --bindir="$HOME/bin" --enable-static
make
make install

# 7 - Compile x265

cd ~/ffmpeg_sources
git clone https://bitbucket.org/multicoreware/x265_git
cd ~/ffmpeg_sources/x265_git/build/linux
cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX="$HOME/ffmpeg_build" -DENABLE_SHARED:bool=off ../../source
make
make install

# 8 - Compile the AAC audio codec

cd ~/ffmpeg_sources
git clone --depth 1 https://github.com/mstorsjo/fdk-aac
cd fdk-aac
autoreconf -fiv
./configure --prefix="$HOME/ffmpeg_build" --disable-shared
make
make install

# 9 - Compile MP3 codec

cd ~/ffmpeg_sources
curl -O -L https://downloads.sourceforge.net/project/lame/lame/3.100/lame-3.100.tar.gz
tar xzvf lame-3.100.tar.gz
cd lame-3.100
./configure --prefix="$HOME/ffmpeg_build" --bindir="$HOME/bin" --disable-shared
make
make install

# 10 - Compile the Opus codec

cd ~/ffmpeg_sources
curl -O -L https://archive.mozilla.org/pub/opus/opus-1.3.1.tar.gz
tar xzvf opus-1.3.1.tar.gz
cd opus-1.3.1
./configure --prefix="$HOME/ffmpeg_build" --disable-shared
make
make install

export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib64/
cp /usr/local/lib64/pkgconfig/libvmaf.pc $HOME/ffmpeg_build/lib/pkgconfig/

# 11 - Compile FFmpeg

cd ~/ffmpeg_sources
curl -O -L https://ffmpeg.org/releases/ffmpeg-snapshot.tar.bz2
tar xjvf ffmpeg-snapshot.tar.bz2
cd ffmpeg
PATH="$HOME/bin:$PATH" PKG_CONFIG_PATH="$HOME/ffmpeg_build/lib/pkgconfig" ./configure \
  --prefix="$HOME/ffmpeg_build" \
  --pkg-config-flags="--static" \
  --extra-cflags="-I$HOME/ffmpeg_build/include" \
  --extra-ldflags="-L$HOME/ffmpeg_build/lib" \
  --extra-libs=-lpthread \
  --extra-libs=-lm \
  --bindir="$HOME/bin" \
  --enable-gpl \
  --enable-libfdk_aac \
  --enable-libfreetype \
  --enable-libmp3lame \
  --enable-libopus \
  --enable-libx264 \
  --enable-libx265 \
  --enable-nonfree
make
make install

cd ~/bin
hash -d ./ffmpeg
./ffmpeg -codecs | grep libx26

# 12 - Remove build and source directories to free up disk space

# rm -rf ffmpeg_build/ ffmpeg_sources/

# done
printf "\nDone.\n"


