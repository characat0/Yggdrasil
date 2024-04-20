# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "LightGBM"
version = v"4.0.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/microsoft/LightGBM.git", "d73c6b530b39a18a3cacaafc4e42550be853c036"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/LightGBM
git submodule update --init --depth=1
git submodule update --checkout --depth=1


if [[ $target == *"apple-darwin"* ]]; then
  cmake_extra_args="-DAPPLE=1 -DAPPLE_OUTPUT_DYLIB=1"
fi

FLAGS=()

if [[ "${target}" == *-mingw* ]]; then
  cmake_extra_args="-DWIN32=1 -DMINGW=1"
  FLAGS+=(LDFLAGS="-no-undefined")
fi

cmake \
  -DCMAKE_INSTALL_PREFIX=$prefix\
  -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
  -DCMAKE_BUILD_TYPE=Release \
  $cmake_extra_args
make -j1 "${FLAGS[@]}"
make install
install_license LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("lib_lightgbm", :lib_lightgbm),
    ExecutableProduct("lightgbm", :lightgbm),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    # For OpenMP we use libomp from `LLVMOpenMP_jll` where we use LLVM as compiler (BSD
    # systems), and libgomp from `CompilerSupportLibraries_jll` everywhere else.
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"); platforms=filter(!Sys.isbsd, platforms)),
    Dependency(PackageSpec(name="LLVMOpenMP_jll", uuid="1d63c593-3942-5779-bab2-d838dc0a180e"); platforms=filter(Sys.isbsd, platforms)),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"7.1.0")
