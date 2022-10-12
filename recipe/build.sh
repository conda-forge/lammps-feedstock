#!/bin/bash

args=""
args+=" -D DOWNLOAD_KIM=OFF"
args+=" -D PKG_ASPHERE=ON"
args+=" -D PKG_BODY=ON"
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
args+=" -D PKG_PERI=ON"
args+=" -D PKG_PHONON=ON"
args+=" -D PKG_PLUGIN=ON"
args+=" -D PKG_REAXFF=ON"
args+=" -D PKG_REPLICA=ON"
args+=" -D PKG_RIGID=ON"
args+=" -D PKG_SHOCK=ON"
args+=" -D PKG_SRD=ON"
args+=" -D PKG_USER-VCSGC=ON"
args+=" -D PKG_VORONOI=ON"
args+=" -D WITH_GZIP=ON"

# Plugins 
cp -r lammps-plugins/USER-VCSGC src

# Mlip and n2p2
if [[ -z "$MACOSX_DEPLOYMENT_TARGET" ]]; then
  args=$args" -D PKG_USER-MLIP=ON -D PKG_ML-HDNNP=ON -D DOWNLOAD_N2P2=OFF -D N2P2_DIR=${PREFIX} -D PKG_ML-QUIP=ON -D PKG_LATTE=ON -D DOWNLOAD_QUIP=OFF"
  export LDFLAGS="-L$PREFIX/lib -lcblas -lblas -llapack -fopenmp $LDFLAGS"
  cp -r mlip/LAMMPS/USER-MLIP src/
fi

# pypy does not support LAMMPS internal Python 
PYTHON_IMPL=$($PYTHON -c "import platform; print(platform.python_implementation())")
if [ "$PYTHON_IMPL" != "PyPy" ]; then
  args=$args" -D MLIAP_ENABLE_PYTHON=ON -D PKG_PYTHON=ON -D Python_ROOT_DIR=${PREFIX} -D Python_FIND_STRATEGY=LOCATION"
fi

# Serial
mkdir build_serial
cd build_serial
cmake -D BUILD_MPI=OFF -D BUILD_OMP=OFF -D PKG_MPIIO=OFF $args ${CMAKE_ARGS} ../cmake
make # -j${NUM_CPUS}
cp lmp $PREFIX/bin/lmp_serial
cd ..

# Parallel
export LDFLAGS="-L$PREFIX/lib -lmpi $LDFLAGS"
mkdir build_mpi
cd build_mpi
cmake -D BUILD_MPI=ON -D PKG_MPIIO=ON $args ${CMAKE_ARGS} ../cmake 
make # -j${NUM_CPUS}
cp lmp $PREFIX/bin/lmp_mpi
cd ..

# Library
mkdir build_lib
cd build_lib
cmake -D BUILD_LIB=ON -D BUILD_SHARED_LIBS=ON -D BUILD_MPI=ON -D PKG_MPIIO=ON -D LAMMPS_EXCEPTIONS=yes $args ${CMAKE_ARGS} ../cmake
make # -j${NUM_CPUS}
cp liblammps${SHLIB_EXT}* ../src  # For compatibility with the original make system.
cd ../python
$PYTHON -m pip install . --no-deps -vv
cd ../src
mkdir -p $PREFIX/include/lammps
cp library.h $PREFIX/include/lammps
cp liblammps${SHLIB_EXT}* "${PREFIX}"/lib/
cd ..
