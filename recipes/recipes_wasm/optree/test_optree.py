from dataclasses import dataclass

import optree


def test_flatten_unflatten():
    tree = {"a": [1, 2], "b": (3, None)}
    leaves, spec = optree.tree_flatten(tree)
    assert leaves == [1, 2, 3]
    assert optree.tree_unflatten(spec, leaves) == tree
    assert optree.tree_map(lambda value: value * 2, tree) == {
        "a": [2, 4], "b": (6, None)
    }


def test_custom_node():
    @dataclass
    class Pair:
        left: object
        right: object

    optree.register_pytree_node(
        Pair,
        lambda pair: ((pair.left, pair.right), None),
        lambda metadata, children: Pair(*children),
        namespace="recipe-test",
    )
    try:
        tree = Pair(1, [2, 3])
        leaves, spec = optree.tree_flatten(tree, namespace="recipe-test")
        assert leaves == [1, 2, 3]
        assert optree.tree_unflatten(spec, leaves) == tree
    finally:
        optree.unregister_pytree_node(Pair, namespace="recipe-test")
