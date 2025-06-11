#!/bin/bash

args=""
args+=" -D DOWNLOAD_KIM=OFF"
args+=" -D PKG_ASPHERE=ON"
args+=" -D PKG_BODY=ON"
args+=" -D PKG_BROWNIAN=ON"
args+=" -D PKG_CLASS2=ON"
args+=" -D PKG_COLLOID=ON"
args+=" -D PKG_COLVARS=ON"
args+=" -D PKG_COMPRESS=OFF"
args+=" -D PKG_CORESHELL=ON"
args+=" -D PKG_DIPOLE=ON"
args+=" -D PKG_EXTRA-COMPUTE=ON"
args+=" -D PKG_EXTRA-DUMP=ON"
args+=" -D PKG_EXTRA-FIX=ON"
args+=" -D PKG_EXTRA-MOLECULE=ON"
args+=" -D PKG_EXTRA-PAIR=ON"
args+=" -D PKG_FEP=ON"
args+=" -D PKG_GPU=OFF"
args+=" -D PKG_GRANULAR=ON"
args+=" -D PKG_H5MD=ON"
args+=" -D PKG_KIM=ON"
args+=" -D PKG_KOKKOS=OFF"
args+=" -D PKG_KSPACE=ON"
args+=" -D PKG_MANYBODY=ON"
args+=" -D PKG_MC=ON"
args+=" -D PKG_MEAM=ON"
args+=" -D PKG_MISC=ON"
args+=" -D PKG_MISC=ON"
args+=" -D PKG_ML-IAP=ON"
args+=" -D PKG_ML-PACE=ON"
args+=" -D PKG_ML-SNAP=ON"
args+=" -D PKG_MOLECULE=ON"
args+=" -D PKG_MSCG=OFF"
args+=" -D PKG_NETCDF=ON"
args+=" -D PKG_OPT=ON"
args+=" -D PKG_OPENMP=ON"
args+=" -D PKG_PERI=ON"
args+=" -D PKG_PHONON=ON"
args+=" -D PKG_PLUGIN=ON"
args+=" -D PKG_REAXFF=ON"
args+=" -D PKG_REPLICA=ON"
args+=" -D PKG_RIGID=ON"
args+=" -D PKG_SHOCK=ON"
args+=" -D PKG_SRD=ON"
args+=" -D PKG_VORONOI=ON"
args+=" -D WITH_GZIP=ON"
# plumed
args+=" -D PKG_PLUMED=yes"
args+=" -D PLUMED_MODE=runtime"
# electrode
args+=" -D PKG_ELECTRODE=yes"

# Plugins - n2p2 and latte
if [[ -z "$MACOSX_DEPLOYMENT_TARGET" ]]; then
  if [[ ${PY_VER} != "3.12" ]]; then
    args=$args" -D PKG_ML-QUIP=ON"
  fi
  args=$args" -D PKG_ML-HDNNP=ON -D DOWNLOAD_N2P2=OFF -D N2P2_DIR=${PREFIX} -D PKG_LATTE=ON -D DOWNLOAD_QUIP=OFF"
  export LDFLAGS="-L$PREFIX/lib -lcblas -lblas -llapack -fopenmp $LDFLAGS"
  if [[ ${cuda_compiler_version} != "None" ]]; then
    args=$args" -D PKG_KOKKOS=yes -D Kokkos_ENABLE_CUDA=yes ${Kokkos_OPT_ARGS}"
  fi
else
  CXXFLAGS="${CXXFLAGS} -DTARGET_OS_OSX=1"
fi

# pypy does not support LAMMPS internal Python
PYTHON_IMPL=$($PYTHON -c "import platform; print(platform.python_implementation())")
if [ "$PYTHON_IMPL" != "PyPy" ]; then
  args=$args" -D PKG_USER-M3GNET=ON -D MLIAP_ENABLE_PYTHON=ON -D PKG_PYTHON=ON -D Python_ROOT_DIR=${PREFIX} -D Python_FIND_STRATEGY=LOCATION"
  # Fix Cython symbol conflicts: __pyx_CommonTypesMetaclass_get_module in LAMMPS ML-IAP package:
  # https://docs.lammps.org/Packages_details.html#pkg-ml-iap
  # conflict: mliap_unified_couple.cpp and mliap_model_python_couple.cpp (CPython only)
  # Safe due to Python's namespace isolation and identical Cython-generated code
  # TODO: Remove when upstream fixes duplicate Cython symbols
  if [[ -z "$MACOSX_DEPLOYMENT_TARGET" ]]; then # only for linux
    export LDFLAGS="-Wl,--allow-multiple-definition ${LDFLAGS}"
  fi
fi

# Parallel and library
export LDFLAGS="-L$PREFIX/lib $LDFLAGS"

if [ "${mpi}" == "nompi" ]; then
  ENABLE_MPI=OFF
else
  ENABLE_MPI=TRUE
  export LDFLAGS="-lmpi ${LDFLAGS}"
fi

# Mlip - only available in lmp_mpi 
if [[ -z "$MACOSX_DEPLOYMENT_TARGET" ]]; then
  args=$args" -D PKG_USER-MLIP=ON"
  cp -r mlip/LAMMPS/USER-MLIP src/
fi
mkdir build
cd build
cmake -D BUILD_LIB=ON -D BUILD_SHARED_LIBS=ON -D LAMMPS_INSTALL_RPATH=ON -D BUILD_MPI=${ENABLE_MPI} -D PKG_MPIIO=${ENABLE_MPI} -D LAMMPS_EXCEPTIONS=yes $args ${CMAKE_ARGS} ../cmake
make # -j${NUM_CPUS}
cp lmp $PREFIX/bin/lmp
if [ "${mpi}" == "nompi" ]; then
  ln -s lmp ${PREFIX}/bin/lmp_serial
else
  ln -s lmp ${PREFIX}/bin/lmp_mpi
fi

cp liblammps${SHLIB_EXT}* ../src  # For compatibility with the original make system.
cd ../python
$PYTHON -m pip install . --no-deps -vv
cd ../src
mkdir -p $PREFIX/include/lammps
cp library.h $PREFIX/include/lammps
cp -a liblammps*${SHLIB_EXT}* "${PREFIX}"/lib/
if [[ "${target_platform}" == "osx-64" ]] || [[ "${target_platform}" == "osx-arm64" ]]; then
  ln -s liblammps.dylib ${PREFIX}/lib/liblammps.0.dylib
fi
cd ..
