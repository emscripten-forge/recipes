import pytest
import textwrap
from tree_sitter import Language, Parser

def test_tree_sitter_go():
    """Test that tree-sitter-go can parse Go code correctly."""
    import tree_sitter_go

    GO_LANGUAGE = Language(tree_sitter_go.language())
    parser = Parser(GO_LANGUAGE)

    code = bytes(
        textwrap.dedent(
            """
        func foo() {
            if bar {
                baz()
            }
        }
        """
        ),
        "utf-8",
    )
    tree = parser.parse(code)
    root_node = tree.root_node

    assert str(root_node) == (
        "(source_file "
        "(function_declaration "
        "name: (identifier) "
        "parameters: (parameter_list) "
        "body: (block "
        "(statement_list "
        "(if_statement "
        "condition: (identifier) "
        "consequence: (block "
        "(statement_list "
        "(expression_statement "
        "(call_expression "
        "function: (identifier) "
        "arguments: (argument_list))))))))))"
    )