
def test_basic_function():
	from qutip import *
	print(Qobj())

def test_more_functions():
	from qutip import *
	import numpy as np

	coherent(5,0.5-0.5j)
	q = destroy(4)
	assert(q.dims == [[4], [4]])
	assert(q.shape == (4, 4))
	assert(q.isherm == False)
	assert(q.type == 'oper')

	x = sigmax()

	a = q + 5
	b = x * x

	c = q ** 3

	d = x / np.sqrt(2)