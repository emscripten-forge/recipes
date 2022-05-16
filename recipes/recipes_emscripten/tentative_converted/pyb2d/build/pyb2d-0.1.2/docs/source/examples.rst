.. role:: bash(code)
   :language: bash

Examples
=================


Folder Structure
**********************

The examples subfolder contains C++ examples which
shall show the usage of the C++ library.

::

    pybox2d
    ├── ...
    ├── examples          
    │   ├── CMakeLists.txt
    │   ├── hello_world.cpp
    ├── ...


Build System
**********************

There is a meta target called :bash:`examples` which bundles the
build process of all cpp files in the folder examples in one target.
Assuming you cmake-build directory is called :bash:`bld` the following
will build all examples.

.. code-block:: shell

    $ cd bld
    $ make examples


Adding New Examples
**********************

To add new examples just add a new cpp file to the example
folder and update the :bash:`CMakeLists.txt`.
Assuming we named the new cpp file :bash:`my_new_example.cpp`, 
the relevant part in the :bash:`CMakeLists.txt` shall look like this:

.. code-block:: cmake

    # all examples
    set(CPP_EXAMPLE_FILES
       hello_world.cpp
       my_new_example.cpp
    )




After changing the :bash:`CMakeLists.txt` cmake needs to be rerun
to configure the build again.
After that  :bash:`make examples` will build all examples including the
freshly added examples.

.. code-block:: shell

    $ cd bld
    $ cmake .
    $ make examples