def test_basic():
    import numpy as np
    from skimage import color, data
    from skimage.util import view_as_blocks

    # from skimage import io
    # io.use_plugin('matplotlib', 'imread')

    # get astronaut from skimage.data in grayscale
    print("1")
    a = data.astronaut()
    print("2")
    l = color.rgb2gray(a)#.astype(np.float32)
    assert l.size == 262144
    assert l.shape == (512, 512)

    # size of blocks
    block_shape = (4, 4)
    print("3")
    # see astronaut as a matrix of blocks (of shape block_shape)
    view = view_as_blocks(l, block_shape)
    assert view.shape == (128, 128, 4, 4)

    from skimage.filters import threshold_otsu

    print("4")
    to = threshold_otsu(l)
    print("4.1")
    assert to.hex() == "0x1.8e00000000000p-2"
    print("4.2")
    from skimage.color import rgb2gray
    print("4.3")
    from skimage.data import astronaut
    print("4.4")
    from skimage.filters import sobel
    print("4.5")
    from skimage.segmentation import felzenszwalb, quickshift, slic, watershed
    print("4.6")
    from skimage.util import img_as_float

    print("5")
    img = img_as_float(astronaut()[::2, ::2])

    print("6")
    segments_fz = felzenszwalb(img, scale=100, sigma=0.5, min_size=50)

    print("7")
    segments_slic = slic(img, n_segments=250, compactness=10, sigma=1)

    print("8")
    segments_quick = quickshift(img, kernel_size=3, max_dist=6, ratio=0.5)
    print("9")
    grayscale = rgb2gray(img)
    print("10")
    gradient = sobel(grayscale)
    print("11")
    segments_watershed = watershed(gradient, markers=250, compactness=0.001)
    print("12")
    assert len(np.unique(segments_fz)) == 194
    assert len(np.unique(segments_slic)) == 196
    assert len(np.unique(segments_quick)) == 695
    assert len(np.unique(segments_watershed)) == 256
