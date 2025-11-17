FROM debian:trixie-20251103 AS rocm_trixie_vscode

ENV DEBIAN_FRONTEND=noninteractive
ENV DEBCONF_NONINTERACTIVE_SEEN=true

RUN sed -i 's/^Components: main$/& contrib non-free/' /etc/apt/sources.list.d/debian.sources && \
	apt update -q && apt install --no-upgrade -y -qq apt-utils ca-certificates sed gnupg locales sudo unzip wget && \
	sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && dpkg-reconfigure locales \
	wget -O - https://bazel.build/bazel-release.pub.gpg | gpg --dearmor -o /etc/apt/keyrings/bazel-release.gpg \
	echo "deb [arch=amd64, signed-by=/etc/apt/keyrings/bazel-release.gpg] http://storage.googleapis.com/bazel-apt stable jdk1.8" | sudo tee /etc/apt/sources.list.d/bazel.list > /dev/null
#	wget https://storage.googleapis.com/git-repo-downloads/repo -O /usr/bin/repo && \
#	chmod a+x /usr/bin/repo

ARG PKG_JAX=binutils-gold bazel-7.4.1 libxml2-dev patchelf clang-18 lld-18

RUN apt update && apt install --no-upgrade --no-install-recommends -y -qq \
	curl git git-lfs file fakeroot rsync cpio build-essential cmake ninja-build ccache \
	rpm gfortran libgtest-dev libgmock-dev \
	libboost-all-dev libgrpc-dev googletest ocaml-platform libfmt-dev nasm yasm \
	libdwarf-dev libelf-dev libdw-dev libpci-dev libgmp-dev libmpfr-dev libsqlite3-dev \
	libbz2-dev nlohmann-json3-dev libfdeep-dev libeigen3-dev libfplus-dev \
	zlib1g-dev libhdf5-dev libblis-serial-dev libmsgpack-cxx-dev libblas-dev \
	libdrm-dev mesa-common-dev libva-dev libglew-dev libsystemd-dev libnuma-dev libomp-dev \
	libopenblas-dev libfftw3-dev libopencv-dev ocl-icd-opencl-dev libva-dev \
	mpich pigz re2c redis-tools xxd xsltproc \
	python3 python3-numpy python3-dev python3-pip python3-venv python3-wheel python3-barectf python3-yaml \
	python3-requests python3-setuptools python3-msgpack python3-lxml python3-pygit2 python3-tqdm \
	python3-sphinx python3-myst-parser python3-websockets python3-git python3-tqdm python3-joblib \
	python3-pyelftools debhelper-compat llvm jq \
	ffmpeg libavcodec-dev libavformat-dev libavutil-dev libswscale-dev x265 fdkaac \
	doxygen texinfo texlive bison flex libtool gettext $PKG_JAX

RUN pip3 install --break-system-packages CppHeaderParser

# rocSOLVER and others need libcblas.a for their tests: https://github.com/ROCm/rocSOLVER/blob/develop/install.sh#L178
ARG lapack_version=3.9.1
RUN mkdir /tmp/lapack && wget -qO- https://github.com/Reference-LAPACK/lapack/archive/refs/tags/v$lapack_version.tar.gz | gunzip | \
	tar xvf - --strip-components 1 -C /tmp/lapack
RUN cmake -S/tmp/lapack -B/tmp/lapack.build \
	-GNinja -DCMAKE_BUILD_TYPE=Release \
	-DCMAKE_Fortran_FLAGS=-fno-optimize-sibling-calls \
	-DBUILD_TESTING=OFF -DCBLAS=ON -DLAPACKE=OFF && \
	cmake --build /tmp/lapack.build && \
	cmake --build /tmp/lapack.build --target install

# rocrdecode looks in /opt/amdgpu for the include, instead of (also) in the system folder
RUN mkdir -p /opt/amdgpu && sudo ln -s /usr/include /opt/amdgpu/include

RUN echo "/opt/rocm/lib" >> /etc/ld.so.conf.d/rocm.conf && \
	ldconfig

# '/usr/local/bin/ccache' is hardcoded in the build scripts, so symlink that:
RUN for p in amdclang amdclang++ hipcc ccache; do ln -sv /usr/bin/ccache /usr/local/bin/$p; done
RUN update-ccache-symlinks
ENV PATH="/usr/lib/ccache:$PATH:/opt/rocm"

# The build scripts use python in their shebang, instead of python3
RUN update-alternatives --install /usr/local/bin/python python /usr/bin/python3 3 && \
	update-alternatives --install /usr/local/bin/clang clang /usr/bin/clang-18 18 && \
	update-alternatives --install /usr/local/bin/clang++ clang++ /usr/bin/clang++-18 18

RUN echo "%sudo ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# VSCode used to make it's own user, but can not overwrite existing ones.
# So stop that build here, continue below for a command-line dockerfile
FROM rocm_trixie_vscode AS rocm_trixie

RUN groupadd -g 105 render && groupadd -g 1000 rocm
RUN useradd --system --create-home -u 1000 -g 1000 rocm && \
	usermod -aG sudo,video,render rocm && \
	mkdir -p /home/rocm/.cache/pip
USER rocm
