#!/usr/bin/env python

import cvxpy as cp
import numpy as np

def test_basic_import():
    """Test that cvxpy can be imported and basic functionality works."""
    print("Testing cvxpy-base import...")
    
    # Test basic variable creation
    x = cp.Variable()
    print("✓ Variable creation works")
    
    # Test parameter creation
    p = cp.Parameter()
    print("✓ Parameter creation works")
    
    # Test simple problem formulation (don't solve)
    objective = cp.Minimize(cp.square(x - 1))
    constraint = [x >= 0]
    problem = cp.Problem(objective, constraint)
    print("✓ Problem formulation works")
    
    # Test that we can check if problem is convex
    print(f"✓ Problem is convex: {problem.is_dcp()}")
    
    # Test available solvers (should include OSQP and CLARABEL)
    installed_solvers = cp.installed_solvers()
    print(f"✓ Available solvers: {installed_solvers}")
    
    # Verify we have at least one of the expected solvers
    expected_solvers = ['OSQP', 'CLARABEL']
    available_expected = [s for s in expected_solvers if s in installed_solvers]
    if available_expected:
        print(f"✓ Found expected solvers: {available_expected}")
    else:
        print(f"⚠ Warning: None of expected solvers {expected_solvers} found in {installed_solvers}")
    
    print("cvxpy-base import test completed successfully!")

if __name__ == "__main__":
    test_basic_import()