def test_import_iminuit():
    import iminuit


def test_basics():
    import numpy as np
    from iminuit import Minuit
    from iminuit.cost import UnbinnedNLL
    from scipy.stats import norm
    
    x = norm.rvs(size=1000, random_state=1)
    
    def pdf(x, mu, sigma):
        return norm.pdf(x, mu, sigma)
    
    # Negative unbinned log-likelihood, you can write your own
    cost = UnbinnedNLL(x, pdf)
    m = Minuit(cost, mu=0, sigma=1)
    m.limits["sigma"] = (0, np.inf)
    m.migrad()  # find minimum
    m.hesse()   # compute uncertainties
