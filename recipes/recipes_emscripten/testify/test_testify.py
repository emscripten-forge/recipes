
def test_import():
    print("Importing scipy...")
    import scipy
    
    # using a function from scipy to check if it works
    from scipy import linalg
    a = [[1, 2], [3, 4]]
    print("Calculating inverse of a matrix using scipy.linalg.inv...")
    inv_a = linalg.inv(a)
    print("Inverse calculated successfully:", inv_a)    