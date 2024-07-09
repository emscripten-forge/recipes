# this test is taken from the conda forge feedstock for cartopy: 
# https://github.com/conda-forge/cartopy-feedstock/blob/main/recipe/run_test.py

def test_cartopy():
    import cartopy.crs as ccrs

    import matplotlib
    matplotlib.use('agg')
    import matplotlib.pyplot as plt

    ax = plt.axes(projection=ccrs.Robinson())
    ax.coastlines()
