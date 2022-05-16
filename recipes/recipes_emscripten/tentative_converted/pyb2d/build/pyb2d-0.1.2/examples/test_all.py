from color_mixing import ColorMixing
from function_shape import FunctionShape
from gauss_machine import GaussMachine
import b2d
from b2d.testbed.backend.no_gui import NoGui



import pytest


examples = [
    FunctionShape,
]

lf_examples = [
    ColorMixing,
    GaussMachine,
]


if b2d.BuildConfiguration.LIQUID_FUN:
    examples.extend(lf_examples)






@pytest.mark.parametrize("example_cls", 
    examples
)
def test_eval(example_cls):
    gui_settings = {
    }
    print(f"\nSimulate `{example_cls.name}:`")
    example_cls.run(NoGui, gui_settings=gui_settings)