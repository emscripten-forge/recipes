def test_pybind11():
    import pybind11

    print("\nVERSION:", pybind11.version_info)
    print(pybind11.get_include())
    print(pybind11.get_cmake_dir())
    print(pybind11.get_pkgconfig_dir())
