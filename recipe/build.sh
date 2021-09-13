#!/bin/bash

args="-D PKG_ASPHERE=ON -DPKG_BODY=ON -D PKG_CLASS2=ON -D PKG_ML-IAP=ON -D PKG_COLLOID=ON -D PKG_COMPRESS=OFF -D PKG_CORESHELL=ON -D PKG_DIPOLE=ON -D PKG_H5MD=ON -D PKG_GRANULAR=ON -D PKG_KSPACE=ON -D PKG_MANYBODY=ON -D PKG_MC=ON -D PKG_MISC=ON -D PKG_MOLECULE=ON -D PKG_PERI=ON -D PKG_REPLICA=ON -D PKG_RIGID=ON -D PKG_SHOCK=ON -D PKG_ML-SNAP=ON -D PKG_SRD=ON -D PKG_OPT=ON -D PKG_KIM=ON -D PKG_GPU=OFF -D PKG_KOKKOS=OFF -D PKG_MSCG=OFF -D PKG_MEAM=ON -D PKG_PHONON=ON -D PKG_REAXFF=ON -D WITH_GZIP=ON -D PKG_USER-VCSGC=ON -D PKG_MISC=ON -D PKG_COLVARS=ON -D PKG_EXTRA-COMPUTE=ON -D PKG_EXTRA-DUMP=ON -D PKG_EXTRA-FIX=ON -D PKG_EXTRA-MOLECULE=ON -D PKG_EXTRA-PAIR=ON"

# Plugins 
mkdir src/USER-VCSGC
cp vcsgc-lammps/fix_semigrandcanonical_mc.* src/USER-VCSGC

# Mlip and n2p2
if [[ -z "$MACOSX_DEPLOYMENT_TARGET" ]]; then
  args=$args" -D PKG_USER-MLIP=ON -D PKG_ML-HDNNP=ON -D DOWNLOAD_N2P2=no -D N2P2_DIR=${PREFIX} -D PKG_ML-QUIP=ON -D PKG_LATTE=ON"
  export LDFLAGS="-L$PREFIX/lib -lcblas $LDFLAGS"
  cp -r mlip/src/external/MLIP4LAMMPS/USER-MLIP src/
fi

# pypy does not support LAMMPS internal Python 
PYTHON_IMPL=$($PYTHON -c "import platform; print(platform.python_implementation())")
if [ "$PYTHON_IMPL" != "PyPy" ]; then
  args=$args" -D MLIAP_ENABLE_PYTHON=ON -D PKG_PYTHON=ON -D Python_ROOT_DIR=${PREFIX} -D Python_FIND_STRATEGY=LOCATION"
fi

# Serial
mkdir build_serial
cd build_serial
cmake ${CMAKE_ARGS} -D BUILD_MPI=OFF -D BUILD_OMP=OFF -D PKG_MPIIO=OFF $args ../cmake
make VERBOSE=1 # -j${NUM_CPUS}
cp lmp $PREFIX/bin/lmp_serial
cd ..

# Parallel
export LDFLAGS="-L$PREFIX/lib -lmpi $LDFLAGS"
mkdir build_mpi
cd build_mpi
cmake -D BUILD_MPI=ON -D PKG_MPIIO=ON $args ../cmake 
make VERBOSE=1 # -j${NUM_CPUS}
cp lmp $PREFIX/bin/lmp_mpi
cd ..

# Library
mkdir build_lib
cd build_lib
cmake -D BUILD_LIB=ON -D BUILD_SHARED_LIBS=ON -D BUILD_MPI=ON -D PKG_MPIIO=ON -D LAMMPS_EXCEPTIONS=yes $args ../cmake
make VERBOSE=1 # -j${NUM_CPUS}
cp liblammps${SHLIB_EXT}* ../src  # For compatibility with the original make system.
cd ../src
make install-python 
mkdir -p $PREFIX/include/lammps
cp library.h $PREFIX/include/lammps
cp liblammps${SHLIB_EXT}* "${PREFIX}"/lib/
cd ..
