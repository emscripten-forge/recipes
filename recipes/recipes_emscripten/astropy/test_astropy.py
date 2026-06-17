def test_import_astropy():
    """Test basic imports of core astropy modules."""
    import astropy.units as u
    from astropy.coordinates import SkyCoord
    import astropy.io.ascii
    from astropy.time import Time
    from astropy.table import Table


# =============================================================================
# Units tests
# =============================================================================

def test_units_quantity_creation():
    """Test Quantity creation via operations and constructor."""
    from astropy.units.tests.test_quantity import TestQuantityCreation

    t = TestQuantityCreation()
    t.test_1()  # creation via Unit operations (*, /)
    t.test_2()  # creation via Quantity constructor
    t.test_3()  # invalid unit string raises error
    t.test_nan_inf()  # NaN and Infinity handling


def test_units_quantity_properties():
    """Test Quantity properties and dtype handling."""
    from astropy.units.tests.test_quantity import TestQuantityCreation

    t = TestQuantityCreation()
    t.test_unit_property()
    t.test_preserve_dtype()
    t.test_copy()


def test_units_quantity_arithmetic():
    """Test Quantity arithmetic operations."""
    from astropy.units.tests.test_quantity import TestQuantityOperations

    t = TestQuantityOperations()
    t.test_addition()
    t.test_subtraction()
    t.test_multiplication()
    t.test_division()
    t.test_power()
    t.test_unary()
    t.test_abs()


def test_units_quantity_comparison():
    """Test Quantity comparison operations."""
    from astropy.units.tests.test_quantity import TestQuantityOperations

    t = TestQuantityOperations()
    t.test_comparison()


# =============================================================================
# Time tests
# =============================================================================

def test_time_basic():
    """Test basic Time creation and scale conversion."""
    from astropy.time.tests.test_basic import TestBasic

    t = TestBasic()
    t.test_simple()
    t.test_different_dimensions()


# =============================================================================
# Coordinates tests
# =============================================================================

def test_coordinates_skycoord_init():
    """Test SkyCoord initialization from strings."""
    from astropy.coordinates.tests.test_sky_coord import test_coord_init_string
    test_coord_init_string()


def test_coordinates_skycoord_unit():
    """Test SkyCoord initialization with units."""
    from astropy.coordinates.tests.test_sky_coord import test_coord_init_unit
    test_coord_init_unit()


def test_coordinates_skycoord_list():
    """Test SkyCoord initialization from lists."""
    from astropy.coordinates.tests.test_sky_coord import test_coord_init_list
    test_coord_init_list()


def test_coordinates_transform():
    """Test coordinate frame transformations."""
    from astropy.coordinates.tests.test_sky_coord import test_transform_to
    test_transform_to()


# =============================================================================
# Constants tests
# =============================================================================

def test_constants_speed_of_light():
    """Test speed of light constant."""
    from astropy.constants.tests.test_constant import test_c
    test_c()


def test_constants_planck():
    """Test Planck constant."""
    from astropy.constants.tests.test_constant import test_h
    test_h()


def test_constants_gravity():
    """Test standard gravity constant."""
    from astropy.constants.tests.test_constant import test_g0
    test_g0()


def test_constants_wien():
    """Test Wien's displacement constant."""
    from astropy.constants.tests.test_constant import test_b_wien
    test_b_wien()


# =============================================================================
# IO ASCII tests
# =============================================================================

def test_io_ascii_types():
    """Test ASCII reader type detection."""
    from astropy.io.ascii.tests.test_types import test_types_from_dat
    test_types_from_dat()


def test_io_ascii_rdb_write():
    """Test RDB format writing."""
    from astropy.io.ascii.tests.test_types import test_rdb_write_types
    test_rdb_write_types()


def test_io_ascii_ipac_read():
    """Test IPAC format reading."""
    from astropy.io.ascii.tests.test_types import test_ipac_read_types
    test_ipac_read_types()


# =============================================================================
# Modeling tests
# =============================================================================

def test_modeling_custom_model():
    """Test custom model creation."""
    from astropy.modeling.tests.test_models import test_custom_model_init
    test_custom_model_init()


def test_modeling_custom_model_defaults():
    """Test custom model default parameters."""
    from astropy.modeling.tests.test_models import test_custom_model_defaults
    test_custom_model_defaults()


# =============================================================================
# Table tests
# =============================================================================

def test_table_creation():
    """Test basic Table creation and operations."""
    from astropy.table import Table, Column
    import numpy as np

    # Create table from columns
    a = Column([1, 2, 3], name='a')
    b = Column([4.0, 5.0, 6.0], name='b')
    t = Table([a, b])

    assert len(t) == 3
    assert t.colnames == ['a', 'b']
    assert np.all(t['a'] == [1, 2, 3])

    # Create table from dict
    t2 = Table({'x': [1, 2], 'y': ['a', 'b']})
    assert len(t2) == 2


def test_table_operations():
    """Test Table add/remove columns and rows."""
    from astropy.table import Table
    import numpy as np

    t = Table({'a': [1, 2, 3], 'b': [4, 5, 6]})

    # Add column
    t['c'] = [7, 8, 9]
    assert 'c' in t.colnames

    # Remove column
    del t['c']
    assert 'c' not in t.colnames

    # Slicing
    t2 = t[1:]
    assert len(t2) == 2


# =============================================================================
# NDData tests
# =============================================================================

def test_nddata_import():
    """Test astropy.nddata import.

    This module imports scipy.sparse and is required by downstream
    packages like photutils.
    """
    import astropy.nddata
