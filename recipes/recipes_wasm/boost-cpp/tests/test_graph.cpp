// Functional test for boost-graph, adapted from
// libs/graph/test/dijkstra_cc.cpp and libs/graph/example/dijkstra-example.cpp

#include <boost/graph/adjacency_list.hpp>
#include <boost/graph/dijkstra_shortest_paths.hpp>
#include <boost/property_map/property_map.hpp>
#include <vector>

int main()
{
    using namespace boost;

    typedef adjacency_list<vecS, vecS, directedS, no_property,
                           property<edge_weight_t, int> > Graph;

    Graph g; // 4 vertices, implicit 0..3
    add_edge(0, 1, 1, g);
    add_edge(0, 2, 4, g);
    add_edge(1, 2, 1, g);
    add_edge(1, 3, 2, g);

    std::vector<int> d(num_vertices(g));
    dijkstra_shortest_paths(
        g, vertex(0, g),
        distance_map(make_iterator_property_map(d.begin(),
                                                get(vertex_index, g))));

    // 0->1->2 = 2 beats 0->2 = 4; 0->1->3 = 3
    if (d[0] != 0 || d[1] != 1 || d[2] != 2 || d[3] != 3) return 1;

    return 0;
}