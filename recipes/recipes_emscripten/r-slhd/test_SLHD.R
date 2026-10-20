library(SLHD)

#Maximin-distance Latin hypercube design
D1<-maximinSLHD(t = 1, m = 10, k = 3) 
D1$Design
D1$StandDesign

#Maximin-distance sliced Latin hypercube designs
D2<-maximinSLHD(t = 3, m = 4, k = 2) 
D2$Design
D2$StandDesign