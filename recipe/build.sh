#!/bin/bash

args="-D PKG_ASPHERE=ON -DPKG_BODY=ON -D PKG_CLASS2=ON -D PKG_COLLOID=ON -D PKG_COMPRESS=OFF -D PKG_CORESHELL=ON -D PKG_DIPOLE=ON -D PKG_GRANULAR=ON -D PKG_KSPACE=ON -D PKG_MANYBODY=ON -D PKG_MC=ON -D PKG_MISC=ON -D PKG_MOLECULE=ON -D PKG_PERI=ON -D PKG_REPLICA=ON -D PKG_RIGID=ON -D PKG_SHOCK=ON -D PKG_SNAP=ON -D PKG_SRD=ON -D PKG_OPT=ON -D PKG_KIM=ON -D PKG_GPU=OFF -D PKG_KOKKOS=OFF -D PKG_MSCG=OFF -D PKG_LATTE=OFF -D PKG_USER-MEAMC=ON -D PKG_USER-PHONON=ON -D PKG_USER-REAXC=ON -D WITH_GZIP=ON -D PKG_USER-VCSGC=ON -D PKG_USER-MISC=ON -D PKG_USER-COLVARS=ON -D PKG_USER-PACE=ON"

# Plugins 
mkdir src/USER-VCSGC
cp vcsgc-lammps/fix_semigrandcanonical_mc.* src/USER-VCSGC

# Mlip and n2p2
if [[ -z "$MACOSX_DEPLOYMENT_TARGET" ]]; then
  args=$args" -D PKG_USER-MLIP=ON -D PKG_USER-HDNNP=ON -D PKG_USER-QUIP=ON"
  export LDFLAGS="-L$PREFIX/lib -lcblas $LDFLAGS"
  cp -r mlip/src/external/MLIP4LAMMPS/USER-MLIP src/
fi

# Serial
mkdir build_serial
cd build_serial
cmake -D BUILD_MPI=OFF -D BUILD_OMP=OFF -D PKG_MPIIO=OFF $args ../cmake
make # -j${NUM_CPUS}
cp lmp $PREFIX/bin/lmp_serial
cd ..

# Parallel
export LDFLAGS="-L$PREFIX/lib -lmpi $LDFLAGS"
mkdir build_mpi
cd build_mpi
cmake -D BUILD_MPI=ON -D PKG_MPIIO=ON $args ../cmake 
make # -j${NUM_CPUS}
cp lmp $PREFIX/bin/lmp_mpi
cd ..

# Library
mkdir build_lib
cd build_lib
cmake -D BUILD_LIB=ON -D BUILD_SHARED_LIBS=ON -D BUILD_MPI=ON -D PKG_MPIIO=ON -D LAMMPS_EXCEPTIONS=yes $args ../cmake
make # -j${NUM_CPUS}
cp liblammps${SHLIB_EXT}* ../src  # For compatibility with the original make system.
cd ../src
make install-python 
mkdir -p $PREFIX/include/lammps
cp library.h $PREFIX/include/lammps
cp liblammps${SHLIB_EXT}* "${PREFIX}"/lib/
cd ..
