import pyjs


def test_js_proxy_constructor():
    int_val = pyjs.JsValue(2)
    assert pyjs.type_string(int_val) == "number"

    float_val = pyjs.JsValue(1.0)
    assert pyjs.type_string(float_val) == "number"

    bool_val = pyjs.JsValue(True)
    assert pyjs.type_string(bool_val) == "number"

    string_val = pyjs.JsValue("some_string")
    assert pyjs.type_string(string_val) == "string"


def test_module_propery():

    js_pyobject_cls = pyjs.module_property("pyobject")
    assert pyjs.type_string(js_pyobject_cls) == "function"

    js_pyobject_cls = pyjs.module_property("pyobject_fubar")
    assert pyjs.type_string(js_pyobject_cls) == "undefined"


def test_pre_js():

    _apply_try_catch = pyjs.js_get_global("_apply_try_catch")
    assert pyjs.type_string(_apply_try_catch) == "function"

    _call_py_object_variadic = pyjs.js_get_global("_call_py_object_variadic")
    assert pyjs.type_string(_call_py_object_variadic) == "function"


def test_sleep():
    pass
    pyjs.sleep(1000)
