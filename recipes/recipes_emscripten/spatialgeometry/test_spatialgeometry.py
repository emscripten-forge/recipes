def test_spatialgeometry():
    import spatialgeometry as gm

    # Test cylinder shape
    shape1 = gm.Cylinder(5, 5)
    shape1_check = {
        "stype": "cylinder",
        "t": [0.0, 0.0, 0.0],
        "q": [0.0, 0.0, 0.0, 1.0],
        "v": [0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
        "color": 5000268,
        "opacity": 1.0,
        "radius": 5.0,
        "length": 5.0,
    }
    assert shape1.to_dict() == shape1_check

    # Test sphere color
    shape2 = gm.Sphere(1, color="blue")
    assert shape2.color == (0.0, 0.0, 1.0, 1.0)
