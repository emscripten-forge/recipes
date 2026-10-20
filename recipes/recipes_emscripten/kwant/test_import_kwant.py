import kwant


def test_two_site_system():
    lattice = kwant.lattice.square(norbs=1)
    system = kwant.Builder()
    system[lattice(0, 0)] = 1
    system[lattice(1, 0)] = 2
    system[lattice.neighbors()] = -1

    hamiltonian = system.finalized().hamiltonian_submatrix()
    assert hamiltonian.tolist() == [[1, -1], [-1, 2]]
