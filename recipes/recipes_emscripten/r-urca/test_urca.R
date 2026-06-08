library(urca)

# punitroot/qunitroot expect numeric values, not the formal arg names q/p
q95 <- qunitroot(0.95, trend = "nc", statistic = "t")
print(q95)
stopifnot(is.numeric(q95), length(q95) == 1L, is.finite(q95))

p <- punitroot(1.2836, trend = "nc", statistic = "t")
print(p)
stopifnot(is.numeric(p), length(p) == 1L, p >= 0, p <= 1)

tbl <- unitrootTable(trend = "nc", statistic = "t")
print(tbl)
stopifnot(is.matrix(tbl), nrow(tbl) > 0L)

data(Raotbl1)

data(denmark)
sjd <- denmark[, c("LRM", "LRY", "IBO", "IDE")]
sjd.vecm <- ca.jo(sjd, ecdet = "const", type = "eigen", K = 2, spec = "longrun",
                  season = 4)
HD1 <- matrix(c(1, -1, 0, 0, 0, 0, 0, 1, -1, 0, 0, 0, 0, 0, 1), c(5, 3))
DA <- matrix(c(1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1), c(4, 3))
summary(ablrtest(sjd.vecm, H = HD1, A = DA, r = 1))
