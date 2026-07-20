library(MaxPro)

InitialDesign<-MaxProLHD(n = 10, p = 4)$Design 
DOX<-MaxPro(InitialDesign)
DOX$Design