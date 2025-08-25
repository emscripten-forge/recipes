import rustworkx

def test_isomorphism():
    # Adapted from tests/graph/test_isomorphic.py to work with pytest
    n = 15
    upper_bound_k = (n - 1) // 2
    for k in range(1, upper_bound_k + 1):
        for t in range(k, upper_bound_k + 1):
            result = rustworkx.is_isomorphic(
                rustworkx.generators.generalized_petersen_graph(n, k),
                rustworkx.generators.generalized_petersen_graph(n, t),
            )
            expected = (k == t) or (k == n - t) or (k * t % n == 1) or (k * t % n == n - 1)
            assert result == expected

def test_rayon_works():
    # This essentially tests that multi-threading is set to one core and does not panic
    graph = rustworkx.generators.cycle_graph(10)
    path_lenghts_floyd = rustworkx.floyd_warshall(graph)
    path_lenghts_no_self = rustworkx.all_pairs_dijkstra_path_lengths(graph, lambda _: 1.0)
    path_lenghts_dijkstra = {k: {**v, k: 0.0} for k, v in path_lenghts_no_self.items()}
    assert path_lenghts_floyd == path_lenghts_dijkstra
