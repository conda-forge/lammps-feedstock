# Fix for openMPI
import os

# Test
from lammps import lammps
lmp = lammps()
print("Successfully imported Lammps!")

# mliap test - currenty only working on linux
import platform
if platform.system() == "Linux" and platform.python_implementation() == "CPython":
    from lammps.mliap import activate_mliappy
    print("Successfully imported mliap!")
