import numpy as np
import dynare_preprocessor
from dynare_preprocessor import (
    DynareModel,
    ParserException,
    TapeFun,
    TaylorPerturbation,
    build_dynamic_tape,
    build_static_tape,
)

RBC_MOD = """
var c, r, w, n, k, i, y, a;
varexo epsilon;
parameters beta, delta, khi, eta, alpha, rho, nss;

beta=0.985;
delta=0.025;
nss=0.33;
eta=1.0;
alpha=.33;
rho=.95;
khi=(1-alpha)*(1-nss)^eta/nss*(1/beta-1+delta)/(1/beta-1+delta-delta*alpha);

model;
1/c = beta*(r(1)+1-delta)/c(1);
w = khi*c/(1-n)^eta;
k = (1-delta)*k(-1)+i;
y = a*k(-1)^alpha*n^(1-alpha);
log(a) = rho*log(a(-1))+epsilon;
w = (1-alpha)*y/n;
r = alpha*y/k(-1);
y = c+i;
end;

steady_state_model;
a = 1;
r = 1/beta-1+delta;
n = nss;
k = (alpha/r)^(1/(1-alpha))*n;
y = k^alpha*n^(1-alpha);
w = (1-alpha)*y/n;
i = delta*k;
c = y-i;
end;

shocks;
var epsilon; stderr .009;
end;
"""


def test_dynare_model():
    model = DynareModel(RBC_MOD, derivs_order=2, stochastic=True)
    assert len(model.endogenous) == 8
    assert "y" in model.endogenous
    assert len(model.exogenous) == 1
    assert len(model.parameters) == 7

    y_ss = np.array([model.context[v] for v in model.endogenous])
    e_ss = np.array([model.context[v] for v in model.exogenous])
    ed_ss = np.array([model.context[v] for v in model.exogenous_det])
    p_ss = np.array([model.context[v] for v in model.parameters])

    res = model.residuals(y_ss, y_ss, y_ss, e_ss, ed_ss, p_ss)
    assert res.shape == (8,)
    assert np.max(np.abs(res)) < 1e-12

    blocks = model.jacobian_blocks(y_ss, y_ss, y_ss, e_ss, ed_ss, p_ss)
    assert blocks.curr.shape == (8, 8)
    assert blocks.lag.shape == (8, 8)
    assert blocks.lead.shape == (8, 8)
    assert blocks.exo.shape == (8, 1)

    s_res = model.static_residuals(y_ss, e_ss, ed_ss, p_ss)
    assert np.max(np.abs(s_res)) < 1e-12
    s_jac = model.static_jacobian(y_ss, e_ss, ed_ss, p_ss)
    assert s_jac.shape == (8, 8)


def test_tape():
    model = DynareModel(RBC_MOD, derivs_order=2, stochastic=True)
    y_ss = np.array([model.context[v] for v in model.endogenous])
    e_ss = np.array([model.context[v] for v in model.exogenous])
    p_ss = np.array([model.context[v] for v in model.parameters])

    tf = build_dynamic_tape(model, derivs_order=1)
    out = tf(y_ss, y_ss, y_ss, e_ss, p_ss)
    assert np.max(np.abs(out["residual"])) < 1e-12

    tf.fold_constants({4: list(p_ss)})
    tf.compact()
    js = tf.to_json()
    tf_rt = TapeFun.from_json(js)
    out_rt = tf_rt(y_ss, y_ss, y_ss, e_ss, p_ss)
    assert np.max(np.abs(out_rt["residual"])) < 1e-12

    f_np = tf.to_numpy()
    out_np = f_np(y_ss, y_ss, y_ss, e_ss, p_ss)
    assert np.max(np.abs(out_np["residual"])) < 1e-12

    stf = build_static_tape(model, derivs_order=1)
    sout = stf(y_ss, e_ss, p_ss)
    assert np.max(np.abs(sout["residual"])) < 1e-12


def test_taylor_perturbation():
    model = DynareModel(RBC_MOD, derivs_order=1, stochastic=True)

    # Default (cyclic_reduction + implicit sylvester) up to order 3
    tp = TaylorPerturbation(model, order=3).solve()
    assert tp.order == 3
    assert len(tp.states) == 2
    assert tp.max_residual < 1e-10

    so = tp.second_order()
    assert so.g_x.shape == (8, 8)
    assert so.g_e.shape == (8, 1)
    assert so.g_ss.shape == (8,)

    w0 = np.zeros((1, tp.Nw))
    y0 = tp.g(w0)
    assert y0.shape == (1, 8)

    sim = tp.simulate(T=15, seed=0, pruned=False)
    assert sim["y"].shape == (15, 8)
    assert np.all(np.isfinite(sim["y"]))

    # Schur first-order + block sylvester
    tp_schur = TaylorPerturbation(
        model, order=2, first_order="schur", sylvester="block"
    ).solve()
    assert tp_schur.max_residual < 1e-10
    assert np.allclose(tp.second_order().g_x, tp_schur.second_order().g_x, atol=1e-9)

    # Construct directly from TapeFun
    tf = build_dynamic_tape(model, derivs_order=0)
    y_ss = np.array([model.context[v] for v in model.endogenous])
    p_ss = np.array([model.context[v] for v in model.parameters])
    Sigma = np.array([[0.009**2]])
    tp_tape = TaylorPerturbation(
        tf, order=2, ybar=y_ss, params=p_ss, Sigma=Sigma
    ).solve()
    assert tp_tape.max_residual < 1e-10
    assert np.allclose(tp.second_order().g_x, tp_tape.second_order().g_x, atol=1e-9)


def test_exceptions():
    try:
        DynareModel("var x; model; x = ; end;")
        assert False, "Expected ParserException"
    except ParserException as e:
        assert e.message


if __name__ == "__main__":
    test_dynare_model()
    test_tape()
    test_taylor_perturbation()
    test_exceptions()
    print("All DynareModel, TapeFun, and TaylorPerturbation tests passed!")
