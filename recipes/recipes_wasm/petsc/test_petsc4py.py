def test_petsc4py_solve():
    import petsc4py

    petsc4py.init([])
    from petsc4py import PETSc

    assert petsc4py.__version__ == "3.26.1"

    A = PETSc.Mat().create()
    A.setSizes([3, 3])
    A.setType("dense")
    A.setUp()
    A[0, 0] = 4.0
    A[0, 1] = -1.0
    A[1, 0] = -1.0
    A[1, 1] = 4.0
    A[1, 2] = -1.0
    A[2, 1] = -1.0
    A[2, 2] = 4.0
    A.assemble()

    u = PETSc.Vec().createSeq(3)
    u.set(1.0)
    b = A.createVecRight()
    A.mult(u, b)

    ksp = PETSc.KSP().create()
    ksp.setOperators(A)
    ksp.setType("preonly")
    ksp.getPC().setType("lu")
    x = b.duplicate()
    ksp.solve(b, x)

    x.axpy(-1.0, u)
    assert x.norm() < 1e-10, x.norm()
