import dynare_preprocessor
from dynare_preprocessor import DynareModel

txt = """
var y, c, k, a, h, b;
varexo e, u;
parameters beta, rho, alpha, delta, theta, psi, tau;
alpha = 0.36;
rho   = 0.95;
tau   = 0.025;
beta  = 0.99;
delta = 0.025;
psi   = 0;
theta = 2.95;
phi   = 0.1;
model;
c*theta*h^(1+psi)=(1-alpha)*y;
k = beta*(((exp(b)*c)/(exp(b(+1))*c(+1)))
    *(exp(b(+1))*alpha*y(+1)+(1-delta)*k));
y = exp(a)*(k(-1)^alpha)*(h^(1-alpha));
k = exp(b)*(y-c)+(1-delta)*k(-1);
a = rho*a(-1)+tau*b(-1) + e;
b = tau*a(-1)+rho*b(-1) + u;
end;
"""

def test_dynare_model():
    model = DynareModel(txt)
    assert len(model.endogenous) == 6
    assert "y" in model.endogenous
    assert len(model.exogenous) == 2
    assert len(model.parameters) == 7
    print("All DynareModel tests passed in WebAssembly!")

if __name__ == "__main__":
    test_dynare_model()