import jax
import jax.numpy as jnp
import numpy as np


def test_cpu_jit_and_grad():
    assert jax.default_backend() == "cpu"
    x = np.arange(4, dtype=np.float32)
    value, gradient = jax.jit(jax.value_and_grad(lambda x: jnp.sum(x * x)))(x)
    np.testing.assert_allclose(value, 14.0)
    np.testing.assert_allclose(gradient, 2 * x)


def test_random_and_lapack():
    values = jax.random.uniform(jax.random.key(0), (8,))
    assert np.isfinite(np.asarray(values)).all()
    matrix = np.array([[4.0, 1.0], [1.0, 3.0]], dtype=np.float32)
    rhs = np.array([1.0, 2.0], dtype=np.float32)
    result = jax.jit(jnp.linalg.solve)(matrix, rhs)
    np.testing.assert_allclose(result, np.linalg.solve(matrix, rhs), rtol=1e-5)


def test_stablehlo_export():
    from jax import export

    exported = export.export(jax.jit(lambda x: x * x + 1))(
        jax.ShapeDtypeStruct((4,), jnp.float32)
    )
    assert "stablehlo.multiply" in exported.mlir_module()
