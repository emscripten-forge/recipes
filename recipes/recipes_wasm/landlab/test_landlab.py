import io

import numpy as np


def test_landscape_evolution():
    import matplotlib

    matplotlib.use("Agg")
    import matplotlib.pyplot as plt

    from landlab import RasterModelGrid, imshow_grid
    from landlab.components import FastscapeEroder, FlowAccumulator, LinearDiffuser

    grid = RasterModelGrid((40, 60), xy_spacing=100.0)
    z = grid.add_zeros("topographic__elevation", at="node")
    rng = np.random.default_rng(42)
    z += rng.random(z.size)
    grid.set_closed_boundaries_at_grid_edges(True, True, True, False)

    fa = FlowAccumulator(
        grid, flow_director="D8", depression_finder="DepressionFinderAndRouter"
    )
    sp = FastscapeEroder(grid, K_sp=1e-5, m_sp=0.5, n_sp=1.0)
    ld = LinearDiffuser(grid, linear_diffusivity=0.01)

    uplift_rate = 1e-3
    dt = 1000.0
    core = grid.core_nodes
    for _ in range(100):
        z[core] += uplift_rate * dt
        fa.run_one_step()
        sp.run_one_step(dt)
        ld.run_one_step(dt)

    # uplift built relief, rivers drain towards the open (bottom) edge
    assert z[core].max() > 10.0
    area = grid.at_node["drainage_area"]
    assert area.max() > 10 * grid.dx * grid.dy
    # all water leaves through the open boundary: outflow == total core area
    outflow = area[grid.open_boundary_nodes].sum()
    np.testing.assert_allclose(outflow, grid.number_of_core_nodes * grid.dx * grid.dy)

    fig = plt.figure()
    imshow_grid(grid, "topographic__elevation", cmap="terrain")
    buf = io.BytesIO()
    fig.savefig(buf, format="png")
    plt.close(fig)
    assert buf.getvalue()[:8] == b"\x89PNG\r\n\x1a\n"
    assert len(buf.getvalue()) > 1000
