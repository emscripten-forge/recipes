def test_picomamba():
    import sysconfig

    side = sysconfig.get_paths()["purelib"]

    import glob
    import os

    site = sysconfig.get_paths()["purelib"]
    print(glob.glob(os.path.join(site, "*")))
    import picomamba
