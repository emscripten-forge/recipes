use pyo3::prelude::*;

#[pyfunction]
fn add(a: i64, b: i64) -> i64 {
    a + b
}

#[pymodule]
fn pyo3test(m: &Bound<'_, PyModule>) -> PyResult<()> {
    m.add_function(wrap_pyfunction!(add, m)?)?;
    Ok(())
}
