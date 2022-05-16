.. role:: bash(code)
   :language: bash


Unit Tests
=================

We use doctest_ to create a benchmark for the C++ code.


The test subfolder contains all the code related 
to the C++ unit tests.
In :bash:`main.cpp` implements the benchmarks runner,
The unit tets are implemented in :bash:`test_*.cpp`.
The test older looks like.

::

    pybox2d
    ├── ...
    ├── test
    │   ├── CMakeLists.txt
    │   ├── main.cpp         
    │   ├── test_pybox2d_config.cpp
    ├── ...




Build System
**********************

There is a meta target called :bash:`test_pybox2d` which bundles the
build process of unit tests.
Assuming you cmake-build directory is called :bash:`bld` the following
will build all examples.

.. code-block:: shell

    $ cd bld
    $ make test_cpptools

To run the actual test you can use the target :bash:`cpp_tests`
.. code-block:: shell

    $ cd bld
    $ make cpp_tests


Adding New Tests
**********************

To add new tests just add a new cpp file to the test
folder and update the :bash:`CMakeLists.txt`.
Assuming we named the new cpp file :bash:`test_my_new_feture.cpp`, 
the relevant part in the :bash:`CMakeLists.txt` shall look like this:

.. code-block:: cmake

    # all tests
    set(${PROJECT_NAME}_TESTS
        test_cpptools_config.cpp
        test_my_new_feture.cpp
    )




After changing the :bash:`CMakeLists.txt` cmake needs to be rerun
to configure the build again.
After that  :bash:`make examples` will build all examples including the
freshly added examples.

.. code-block:: shell

    $ cd bld
    $ cmake .
    $ make examples


.. _doctest: https://github.com/google/benchmark
