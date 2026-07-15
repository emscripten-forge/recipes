library(mco)

# 2. Define the conflicting 2-objective function
my_objectives <- function(x) {
  f1 <- (x[1] - 1)^2 + (x[2] + 1)^2
  f2 <- (x[1] + 1)^2 + (x[2] - 1)^2
  return(c(f1, f2))
}

# 3. Run the NSGA-II genetic algorithm
result <- nsga2(
  fn = my_objectives, 
  idim = 2,                    # 2 decision variables
  odim = 2,                    # 2 objectives
  lower.bounds = c(-3, -3), 
  upper.bounds = c(3, 3), 
  popsize = 100, 
  generations = 50
)