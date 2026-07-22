library(reticulate)
print(py_config())
# ==============================================================================
# 1. THE CUSTOM MINI-TESTING FRAMEWORK
# ==============================================================================

.test_results <- list()

expect_equal <- function(current, target, label = "") {
  caller <- if (label != "") label else deparse(substitute(current))
  
  if (isTRUE(all.equal(current, target))) {
    .test_results[[length(.test_results) + 1]] <<- list(status = "PASS", test = caller, msg = "OK")
  } else {
    msg <- paste0("Expected ", capture.output(print(target)), ", got ", capture.output(print(current)))
    .test_results[[length(.test_results) + 1]] <<- list(status = "FAIL", test = caller, msg = msg)
  }
}

run_all_tests <- function(env = .GlobalEnv) {
  .test_results <<- list()
  
  all_objs <- ls(envir = env, pattern = "^test_")
  test_funcs <- all_objs[sapply(all_objs, function(x) is.function(get(x, envir = env)))]
  
  cat(paste("Found", length(test_funcs), "test functions. Running...\n\n"))
  
  for (func_name in test_funcs) {
    cat(paste("Running:", func_name, "... "))
    func <- get(func_name, envir = env)
    
    tryCatch({
      func()
      cat("done.\n")
    }, error = function(e) {
      cat("CRASHED!\n")
      .test_results[[length(.test_results) + 1]] <<- list(
        status = "CRASH", 
        test = func_name, 
        msg = paste("Function panicked:", e$message)
      )
    })
  }
  
  if (length(.test_results) == 0) {
    cat("\n⚠ No assertions were logged.\n")
    return(FALSE)
  }
  
  results_df <- do.call(rbind, lapply(.test_results, as.data.frame))
  
  cat("\n================ TEST SUMMARY ================\n")
  print(results_df)
  
  if (any(results_df$status %in% c("FAIL", "CRASH"))) {
    cat("\n❌ SOME TESTS FAILED\n")
    return(FALSE)
  } else {
    cat("\n🎉 ALL TESTS PASSED SUCCESSFULLY!\n")
    return(TRUE)
  }
}


# ==============================================================================
# 2. THE TEST CASES (Dynamic Discovery)
# ==============================================================================

test_01_environment_config <- function() {
  cat("\n[Environment Setup Verification]\n")
  
}

test_02_basic_evaluation <- function() {
  res_math <- py_eval("2 + 2")
  expect_equal(res_math, 4, label = "Simple Math Evaluation (2+2)")
}

test_03_matrix_roundtrip <- function() {
  np <- import("numpy")
  
  # Create an R matrix and pass it to Python
  r_matrix <- matrix(1:4, nrow = 2, ncol = 2)
  py_matrix <- np$array(r_matrix)
  
  # Round-trip check: Convert back to R and verify equality
  r_matrix_back <- py_to_r(py_matrix)
  
  expect_equal(r_matrix_back, r_matrix, label = "R-to-Python Matrix Roundtrip")
}

test_04_pure_python_array_handling <- function() {
  # Generate data entirely on the Python side using standard types
  py_run_string("import numpy as np; my_arr = np.ones((2, 2)) * 5")
  
  # Bring the result back to R
  r_matrix_back2 <- py$my_arr
  
  # Access and test array elements from R
  at11 <- r_matrix_back2[1, 1]
  expect_equal(at11, 5, label = "Extract Pure Python Array Element")
}

test_05_explicit_r_to_py_casting <- function() {
  r_arr <- matrix(1:4, nrow = 2, ncol = 2)
  py_arr <- r_to_py(r_arr)
  
  # Pulling it right back to verify r_to_py translated accurately 
  expect_equal(py_to_r(py_arr), r_arr, label = "Explicit r_to_py Conversion")
}



# run
run_all_tests()