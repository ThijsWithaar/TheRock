# TheRock - Debian packages

This is a modified repository for AMD's [TheRock](README-TheRock.md) driver/library suite,
which builds .deb packages for Debian Trixie.
The archive includes debian packages for [JAX](https://docs.jax.dev/) and [PyTorch](https://pytorch.org/)
which play nice with the system python and the ROCM libraries of this archive.
It bundles all .debs into a PPA archive, so all packages can be installed via apt.


## Configuration
1. Modify the containerEnv settings in [devcontainer.json](.devcontainer/devcontainer.json)


## Compiling the sources, creating the PPA archive

1. [TODO](docs/environment_setup_guide.md#patchelf): `sudo env INSTALL_PREFIX=/usr/local ./dockerfiles/install_pinned_patchelf.sh`
2. python3 ./build_tools/fetch_sources.py
3. In [VSCode](https://code.visualstudio.com/) open this folder
4. Press `re-open in container`
5. Press `build` (at the bottom toolbar)

Instead of steps 3 .. 5, running [build.sh](build.sh) gives the same result, without requiring VScode.
It will automatically start a docker container if needed.


## Installing the resulting PPA Archive

1. Create the file `/etc/apt.sources.list.d/therock.sources` containing:
  ```
  Types: deb
  URIs: file:/home/.../TheRock/out/build/linux-release-package/apt-repo
  Enabled: yes
  Suites: stable
  Components: main
  Architectures: amd64
  Signed-By: /etc/apt/keyrings/rpi.public.asc
  ```
2. Copy `out/build/linux-release-package/apt-repo/rpi.public.asc` to `/etc/apt/keyrings`.
