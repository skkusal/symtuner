FROM ubuntu:18.04

USER root

# Install system libraries
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        bison \
        build-essential \
        cmake \
        clang-6.0 \
        curl \
        file \
        flex \
        git \
        libboost-all-dev \
        libcap-dev \
        libgoogle-perftools-dev \
        libncurses5-dev \
        libtcmalloc-minimal4 \
        llvm-6.0 \
        llvm-6.0-dev \
        llvm-6.0-tools \
        minisat2 \
        perl \
        python \
        python-pip \
        python3 \
        python3-dev \
        python3-pip \
        python3-setuptools \
        ssh-client \
        sudo \
        unzip \
        zlib1g-dev && \
    apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/*
RUN pip3 install --no-cache-dir wllvm

# Install klee
ENV PATH=/usr/lib/llvm-6.0/bin:$PATH
WORKDIR /opt
RUN git clone -b 2.1.1 --depth 1 https://github.com/stp/stp.git
WORKDIR /opt/stp/build
RUN cmake -DBUILD-SHARED_LIBS:BOOL=OFF -DENABLE_PYTHON_INTERFACE:BOOL=OFF .. && \
    make && \
    make install
WORKDIR /opt
RUN git clone --depth 1 https://github.com/klee/klee-uclibc.git
WORKDIR /opt/klee-uclibc
RUN ./configure --make-llvm-lib  && make -j2
WORKDIR /opt
RUN git clone -b v2.0 --depth 1 https://github.com/klee/klee.git /opt/klee-src
WORKDIR /opt/klee-src
RUN LLVM_VERSION=6.0 SANITIZER_BUILD= BASE=/opt/klee-libcxx ./scripts/build/build.sh libcxx
WORKDIR /opt/klee-bin
RUN cmake \
        -DENABLE_SOLVER_STP=ON \
        -DENABLE_POSIX_RUNTIME=ON \
        -DENABLE_KLEE_UCLIBC=ON \
        -DKLEE_UCLIBC_PATH=/opt/klee-uclibc \
        -DENABLE_KLEE_LIBCXX=ON \
        -DKLEE_LIBCXX_DIR=/opt/klee-libcxx/libc++-install-60 \
        -DKLEE_LIBCXX_INCLUDE_DIR=/opt/klee-libcxx/libc++-install-60/include/c++/v1 \
        -DENABLE_UNIT_TESTS=OFF \
        -DENABLE_SYSTEM_TESTS=OFF \
        /opt/klee-src && \
    make
ENV PATH=/opt/klee-bin/bin:$PATH

# None root user
RUN useradd \
        --shell $(which bash) \
        -G sudo \
        -m -d /home/symtuner -k /etc/skel \
        symtuner && \
    sed -i -e 's/%sudo.*/%sudo\tALL=(ALL:ALL)\tNOPASSWD:ALL/g' /etc/sudoers && \
    touch /home/symtuner/.sudo_as_admin_successful

# Install SymTuner
COPY setup.py README.md /opt/symtuner/
COPY symtuner /opt/symtuner/symtuner
RUN pip3 install /opt/symtuner && symtuner --help

# Workspace setting
RUN mkdir -p /workspaces && chmod 777 /workspaces

# Build benchmarks
USER symtuner
WORKDIR /workspaces
COPY artifact/make-paper-benchmark.sh /workspaces/make.sh
RUN ./make.sh all && rm /workspaces/make.sh

# Libraries for artifact
RUN pip3 install --no-cache-dir --upgrade pip && \
    pip3 install --no-cache-dir \
        matplotlib \
        pandas \
        tabulate

# Entry point
CMD [ "bash" ]
