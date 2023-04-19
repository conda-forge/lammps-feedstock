# Fix for openMPI
import os
os.environ['OMPI_MCA_plm'] = 'isolated'
os.environ['OMPI_MCA_rmaps_base_oversubscribe'] = 'yes'
os.environ['OMPI_MCA_btl_vader_single_copy_mechanism'] = 'none'

# Test
from lammps import lammps
lmp = lammps()
print("Successfully imported Lammps!")

# mliap test - currenty only working on linux
import platform
if platform.system() == "Linux" and platform.python_implementation() == "CPython":
    from lammps.mliap import activate_mliappy
    print("Successfully imported mliap!")
