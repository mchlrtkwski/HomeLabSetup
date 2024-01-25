FROM rockylinux:8.8
SHELL [ "/bin/bash", "-c"]
ENV ANACONDA_ROOT=/root/Anaconda3
ENV TOOLCHAIN_ROOT=${ANACONDA_ROOT}/toolchain
# Lay the Foundation, Install GCC and WGET
RUN yum -y install --nodocs --setopt=tsflags=nodocs --setopt=install_weak_deps=False \
        gcc-toolset-12-gcc \
        gcc-toolset-12-gcc-c++ \
        wget && \
    echo "source /opt/rh/gcc-toolset-12/enable" >> /root/.bashrc 

WORKDIR /tmp/build

# Download the Python Layer and Set the Environmet
RUN export ARCH=$(uname -m) && \
    echo $ARCH && \
    wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-$ARCH.sh && \
    bash Miniconda3-latest-Linux-$ARCH.sh -b -p $ANACONDA_ROOT && \
    rm Miniconda3-latest-Linux-$ARCH.sh && \
    echo "export PATH=$ANACONDA_ROOT/bin:\$PATH" >> /root/.bashrc && \
    rm -rf /tmp/build/*

RUN mkdir -p $TOOLCHAIN_ROOT/include && \
   mkdir -p $TOOLCHAIN_ROOT/lib && \
   mkdir -p $TOOLCHAIN_ROOT/bin && \
   echo "export PATH=$TOOLCHAIN_ROOT/bin:\$PATH" >> /root/.bashrc 

# Modify the Environment
RUN echo "export CPLUS_INCLUDE_PATH=$TOOLCHAIN_ROOT/include:\$CPLUS_INCLUDE_PATH" >> /root/.bashrc && \
    echo "export LIBRARY_PATH=$TOOLCHAIN_ROOT/lib:\$LIBRARY_PATH" >> /root/.bashrc && \
    echo "export LD_LIBRARY_PATH=$TOOLCHAIN_ROOT/lib:\$LD_LIBRARY_PATH" >> /root/.bashrc

# Download and Install Make
RUN source /root/.bashrc && \
    wget https://ftp.gnu.org/gnu/make/make-4.3.tar.gz && \
    tar -xzf make-4.3.tar.gz && \
    cd make-4.3 && \
    source /opt/rh/gcc-toolset-12/enable && \
    ./configure --prefix=$TOOLCHAIN_ROOT && \
    make && \
    make install && \
    rm -rf /tmp/build/*

# Download and Install Tar
RUN source /root/.bashrc && \
    wget https://ftp.gnu.org/gnu/tar/tar-1.35.tar.gz && \
    tar -xvf tar-1.35.tar.gz && \
    cd tar-1.35 && \
    FORCE_UNSAFE_CONFIGURE=1 ./configure --prefix=$TOOLCHAIN_ROOT && \
    make && \
    make install && \
    rm -rf /tmp/build/*

# Download and Install Perl
RUN source /root/.bashrc && \
    wget https://www.cpan.org/src/5.0/perl-5.34.0.tar.gz && \
    tar -xzf perl-5.34.0.tar.gz && \
    cd perl-5.34.0 && \
    ./Configure -des -Dprefix=$TOOLCHAIN_ROOT && \
    make && \
    make install && \
    rm -rf /tmp/build/*

# Download and Install Findutils
RUN source /root/.bashrc && \
    wget https://ftp.gnu.org/gnu/findutils/findutils-4.8.0.tar.xz && \
    tar -xvf findutils-4.8.0.tar.xz && \
    cd findutils-4.8.0 && \
    ./configure --prefix=$TOOLCHAIN_ROOT && \
    make && \
    make install && \
    rm -rf /tmp/build/*

# Download and Install M4
RUN source /root/.bashrc && \
    wget https://ftp.gnu.org/gnu/m4/m4-1.4.19.tar.gz && \
    tar -xzf m4-1.4.19.tar.gz && \
    cd m4-1.4.19 && \
    ./configure --prefix=$TOOLCHAIN_ROOT && \
    make && \
    make install && \
    rm -rf /tmp/build/*

# Download and Install Autoconf
RUN source /root/.bashrc && \
    wget https://ftp.gnu.org/gnu/autoconf/autoconf-2.71.tar.gz && \
    tar -xzf autoconf-2.71.tar.gz && \
    cd autoconf-2.71 && \
    ./configure --prefix=$TOOLCHAIN_ROOT && \
    make && \
    make install && \
    rm -rf /tmp/build/*

# Download and install Zlib
RUN source /root/.bashrc && \
    wget https://www.zlib.net/zlib-1.3.1.tar.gz && \
    tar -xzf zlib-1.3.1.tar.gz && \
    cd zlib-1.3.1 && \
    ./configure --prefix=$TOOLCHAIN_ROOT && \
    make && \
    make install && \
    rm -rf /tmp/build/*

# Downlaod and Install Gettext and Tools
RUN source /root/.bashrc && \
    wget https://ftp.gnu.org/gnu/gettext/gettext-0.21.tar.gz && \
    tar -xzf gettext-0.21.tar.gz && \
    cd gettext-0.21 && \
    ./configure --prefix=$TOOLCHAIN_ROOT && \
    make && \
    make install && \
    cd .. && \
    cd gettext-0.21/gettext-tools && \
    ./configure --prefix=$TOOLCHAIN_ROOT && \
    make && \
    make install && \
    rm -rf /tmp/build/*

# Build OpenSSL
RUN source /root/.bashrc && \
    wget https://www.openssl.org/source/openssl-1.1.1l.tar.gz && \
    tar -xzf openssl-1.1.1l.tar.gz && \
    cd openssl-1.1.1l && \
    ./config --prefix=$TOOLCHAIN_ROOT --openssldir=$TOOLCHAIN_ROOT && \
    make && \
    make install && \
    rm -rf /tmp/build/*
RUN echo "export C_INCLUDE_PATH=$TOOLCHAIN_ROOT/include:\$C_INCLUDE_PATH" >> /root/.bashrc
# Download and Install a Crappy Curl, use vcpkg to build this later
RUN source /root/.bashrc && \
    wget https://curl.se/download/curl-7.78.0.tar.gz && \
    tar -xf curl-7.78.0.tar.gz && \
    cd curl-7.78.0 && \
    ./configure --prefix=$TOOLCHAIN_ROOT --with-openssl --with-libssl-prefix=$TOOLCHAIN_ROOT && \
    make && \
    make install && \
    rm -rf /tmp/build/*

# Start including the C Headers for Zlib

ENV PKG_CONFIG_PATH=${TOOLCHAIN_ROOT}/lib/pkgconfig
# Download and Install Git with https support
RUN source /root/.bashrc && \
    wget https://github.com/git/git/archive/refs/tags/v2.42.0.tar.gz && \
    tar -xzf v2.42.0.tar.gz && \
    cd git-2.42.0 && \
    make configure && \
    ./configure --prefix=$TOOLCHAIN_ROOT && \
    make && \
    make install && \
    rm -rf /tmp/build/*

# Download and Install Zip
RUN source /root/.bashrc && \
    wget https://downloads.sourceforge.net/infozip/zip30.tar.gz && \
    tar -xzf zip30.tar.gz && \
    cd zip30 && \
    make -f unix/Makefile generic && \
    cp zip $TOOLCHAIN_ROOT/bin && \
    cp zipcloak $TOOLCHAIN_ROOT/bin && \
    cp zipnote $TOOLCHAIN_ROOT/bin && \
    cp zipsplit $TOOLCHAIN_ROOT/bin && \
    rm -rf /tmp/build/*

# Download and Install Unzip
RUN source /root/.bashrc && \
    wget https://downloads.sourceforge.net/infozip/unzip60.tar.gz && \
    tar -xzf unzip60.tar.gz && \
    cd unzip60 && \
    make -f unix/Makefile generic && \
    cp unzip $TOOLCHAIN_ROOT/bin && \
    rm -rf /tmp/build/*

# Download and Install Portable CMake
RUN source /root/.bashrc && \
    export ARCH=$(uname -m) && \
    echo $ARCH && \
    wget https://github.com/Kitware/CMake/releases/download/v3.28.1/cmake-3.28.1-linux-$ARCH.tar.gz && \
    tar -xzf cmake-3.28.1-linux-$ARCH.tar.gz && \
    cp -r cmake-3.28.1-linux-$ARCH/* $TOOLCHAIN_ROOT && \
    rm -rf /tmp/build/*
    

# The Code Owners only release x86_64 binaries, so we need to build ninja unfortunately
RUN source /root/.bashrc && \
    wget https://github.com/ninja-build/ninja/archive/refs/tags/v1.11.1.zip && \
    unzip v1.11.1.zip && \
    cd ninja-1.11.1 && \
    ./configure.py --bootstrap && \
    cp ninja $TOOLCHAIN_ROOT/bin && \
    rm -rf /tmp/build/*

# Download and install IPC::Cmd
RUN source /root/.bashrc && \
    wget https://cpan.metacpan.org/authors/id/B/BI/BINGOS/IPC-Cmd-1.04.tar.gz && \
    tar -xzf IPC-Cmd-1.04.tar.gz && \
    cd IPC-Cmd-1.04 && \
    perl Makefile.PL && \
    make && \
    make install && \
    rm -rf /tmp/build/*

WORKDIR /opt/rh/

# Bootstrap or Build VCPKG
RUN echo "export PATH=$TOOLCHAIN_ROOT/bin:\$PATH" >> /root/.bashrc 
RUN source /root/.bashrc && \
    git clone --depth=1 --branch="2023.10.19" http://github.com/microsoft/vcpkg.git && \
    cd vcpkg && \
    chmod +x ./bootstrap-vcpkg.sh && \
    export CMAKE_MAKE_PROGRAM=$TOOLCHAIN_ROOT/bin/make && \
    export VCPKG_FORCE_SYSTEM_BINARIES=1 && \
    ./bootstrap-vcpkg.sh


