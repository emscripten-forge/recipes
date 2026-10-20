library(LiblineaR)

stopifnot(is.function(LiblineaR))
stopifnot(is.function(heuristicC))

# Example extracted from documentation
data(iris)

x=iris[,1:4]
y=factor(iris[,5])
train=sample(1:dim(iris)[1],100)

xTrain=x[train,]
xTest=x[-train,]
yTrain=y[train]
yTest=y[-train]

s=scale(xTrain,center=TRUE,scale=TRUE)

t=6

co=heuristicC(s)
m=LiblineaR(data=s,labels=yTrain,type=t,cost=co,bias=TRUE,verbose=FALSE)

