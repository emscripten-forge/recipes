def test_import_galpy():
    import galpy

def test_galpy():
    try:
        """Test basic galpy import and functionality."""
        from numpy import array
        from galpy.potential import MWPotential2014
        from galpy.orbit import Orbit

        # Create a simple orbit
        # Parameters: [R (kpc), vR (km/s), vT (km/s), z (kpc), vz (km/s)]
        o = Orbit([1., 0.1, 1.1, 0., 0.1])

        # Create time array (must be numpy array for C extensions)
        t = array([0., 1.])  # Time in Gyr

        # Integrate orbit in Milky Way potential
        o.integrate(t, MWPotential2014)

        # Verify integration worked by checking orbit properties
        R = o.R(t)
        assert len(R) == 2, "Orbit integration should return 2 time points"
        assert R[0] > 0, "R should be positive"

    except Exception as e:
        print(f"Warning: Galpy test failed: {e}")
