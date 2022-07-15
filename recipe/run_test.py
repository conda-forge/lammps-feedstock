# Fix for openMPI
import os
os.environ['OMPI_MCA_plm'] = 'isolated'
os.environ['OMPI_MCA_rmaps_base_oversubscribe'] = 'yes'
os.environ['OMPI_MCA_btl_vader_single_copy_mechanism'] = 'none'

# Test
from lammps import lammps

lmp = lammps()