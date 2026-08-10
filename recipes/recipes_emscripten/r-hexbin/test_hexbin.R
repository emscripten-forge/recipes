library(hexbin)

n <- 256

print("LinGray")
print(LinGray (n, beg=1, end=92))
print("BTC")
print(BTC     (n, beg=1, end=256))
print("LinOCS")
print(LinOCS  (n, beg=1, end=256))
print("heat.ob")
print(heat.ob (n, beg=1, end=256))
print("magent")
print(magent  (n, beg=1, end=256))
print("plinrain")
print(plinrain(n, beg=1, end=256))
print("hexbin")
h <- hexbin(rnorm(10000),rnorm(10000))

data(NHANES)
print(summary(NHANES))

set.seed(153)
x <- rnorm(10000)
y <- rnorm(10000)
bin <- hexbin(x,y)

print(smbin  <- smooth.hexbin(bin))
print(erodebin <- erode.hexbin(smbin, cdfcut=.5))