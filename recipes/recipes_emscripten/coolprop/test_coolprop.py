import pytest


def test_import_coolprop():
    import CoolProp
    from CoolProp import CoolProp as CP
    from CoolProp import HumidAirProp  # noqa: F401

    assert CP.PropsSI is not None


def test_import_plots():
    import CoolProp.Plots  # noqa: F401


def test_propssi():
    from CoolProp.CoolProp import PropsSI

    assert round(PropsSI("T", "P", 101325, "Q", 0, "Water"), 3) == 373.124

    with pytest.raises(ValueError):
        PropsSI("T", "P", 101325, "Q", 0, "Walter")


def test_phasesi():
    from CoolProp.CoolProp import PhaseSI

    assert PhaseSI("P", 101325, "Q", 0, "Water") == "twophase"


def test_hapropssi():
    from CoolProp.HumidAirProp import HAPropsSI

    assert round(HAPropsSI("H", "T", 298.15, "P", 101325, "R", 0.5), 3) == 50423.450

    with pytest.raises(ValueError):
        HAPropsSI("H", "T", 298.15, "P", -101325, "R", 0.5)
