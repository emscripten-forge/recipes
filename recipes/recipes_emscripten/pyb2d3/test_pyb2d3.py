import pytest





def  test_import():
    import pyb2d3 as b2d


def test_world_cls():
    import pyb2d3 as b2d
    world = b2d.World(gravity=(0, -10), user_data=42)
    assert world.user_data == 42

    body = world.create_dynamic_body(position=(0, 0), user_data=100)
    assert body.user_data == 100
    body = world.create_static_body(position=(0, -10), user_data=200)
    assert body.user_data == 200
    body = world.create_kinematic_body(position=(0, 10), user_data=300)
    assert body.user_data == 300
