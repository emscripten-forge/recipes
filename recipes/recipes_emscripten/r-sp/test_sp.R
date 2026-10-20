library(sp)

CRS()
CRS("")
CRS(as.character(NA))
CRS("+proj=longlat +datum=WGS84")

data(state)
dd2dms(state.center$x)
dd2dms(state.center$y, NS=TRUE)
print(as.numeric(dd2dms(state.center$y)))
print(as(dd2dms(state.center$y, NS=TRUE), "numeric"))
print(as.numeric.DMS(dd2dms(state.center$y)))
print(state.center$y)

x = GridTopology(c(0,0), c(1,1), c(5,5))
class(x)
x
print(summary(x))
coordinates(x)
y = SpatialGrid(grid = x)
class(y)
print(summary(y))