import pytest
import textwrap
from tree_sitter import Language, Parser

def test_tree_sitter_java():
    """Test that tree-sitter-java can parse Java code correctly."""
    import tree_sitter_java

    JAV_LANGUAGE = Language(tree_sitter_java.language())
    parser = Parser(JAV_LANGUAGE)

    code = bytes(
        textwrap.dedent(
            """
        void foo() {
            if (bar) {
                baz();
            }
        }
        """
        ),
        "utf-8",
    )
    tree = parser.parse(code)
    root_node = tree.root_node

    assert str(root_node) == (
        "(program "
        "(method_declaration "
        "type: (void_type) "
        "name: (identifier) "
        "parameters: (formal_parameters) "
        "body: (block "
        "(if_statement "
        "condition: (parenthesized_expression (identifier)) "
        "consequence: (block "
        "(expression_statement (method_invocation "
        "name: (identifier) "
        "arguments: (argument_list))))))))"
    ) 