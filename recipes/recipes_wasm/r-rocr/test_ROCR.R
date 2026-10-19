print('Loading ROCR package')
library(ROCR)
print('... ROCR package loaded successfully')

test_1 <- function() {
    library(ROCR)
    data(ROCR.hiv)
    attach(ROCR.hiv)
    pred.svm <- prediction(hiv.svm$predictions, hiv.svm$labels)
    pred.svm
    perf.svm <- performance(pred.svm, 'tpr', 'fpr')
    perf.svm
    pred.nn <- prediction(hiv.nn$predictions, hiv.svm$labels)
    pred.nn
    perf.nn <- performance(pred.nn, 'tpr', 'fpr')
    perf.nn
    plot(perf.svm, lty=3, col="red",main="SVMs and NNs for prediction of
    HIV-1 coreceptor usage")
    plot(perf.nn, lty=3, col="blue",add=TRUE)
    plot(perf.svm, avg="vertical", lwd=3, col="red",
         spread.estimate="stderror",plotCI.lwd=2,add=TRUE)
    plot(perf.nn, avg="vertical", lwd=3, col="blue",
         spread.estimate="stderror",plotCI.lwd=2,add=TRUE)
    legend(0.6,0.6,c('SVM','NN'),col=c('red','blue'),lwd=3)
}

test_2 <- function() {
    # plot a ROC curve for a single prediction run
    # and color the curve according to cutoff.
    library(ROCR)
    data(ROCR.simple)
    pred <- prediction(ROCR.simple$predictions, ROCR.simple$labels)
    pred
    perf <- performance(pred,"tpr","fpr")
    perf
    plot(perf,colorize=TRUE)
}

test_3 <- function() {
    # plot ROC curves for several cross-validation runs (dotted
    # in grey), overlaid by the vertical average curve and boxplots
    # showing the vertical spread around the average.
    library(ROCR)
    data(ROCR.xval)
    pred <- prediction(ROCR.xval$predictions, ROCR.xval$labels)
    pred
    perf <- performance(pred,"tpr","fpr")
    perf
    plot(perf,col="grey82",lty=3)
    plot(perf,lwd=3,avg="vertical",spread.estimate="boxplot",add=TRUE)
}

test_4 <- function() {
    # computing a simple ROC curve (x-axis: fpr, y-axis: tpr)
    library(ROCR)
    data(ROCR.simple)
    pred <- prediction( ROCR.simple$predictions, ROCR.simple$labels)
    pred
    perf <- performance(pred,"tpr","fpr")
    perf
    plot(perf)

    # precision/recall curve (x-axis: recall, y-axis: precision)
    perf <- performance(pred, "prec", "rec")
    perf
    plot(perf)

    # sensitivity/specificity curve (x-axis: specificity,
    # y-axis: sensitivity)
    perf <- performance(pred, "sens", "spec")
    perf
    plot(perf)
}

test_5 <- function() {
    # plotting a ROC curve:
    library(ROCR)
    data(ROCR.simple)
    pred <- prediction( ROCR.simple$predictions, ROCR.simple$labels )
    pred
    perf <- performance( pred, "tpr", "fpr" )
    perf
    plot( perf )

    # To entertain your children, make your plots nicer
    # using ROCR's flexible parameter passing mechanisms
    # (much cheaper than a finger painting set)
    par(bg="lightblue", mai=c(1.2,1.5,1,1))
    plot(perf, main="ROCR fingerpainting toolkit", colorize=TRUE,
         xlab="Mary's axis", ylab="", box.lty=7, box.lwd=5,
         box.col="gold", lwd=17, colorkey.relwidth=0.5, xaxis.cex.axis=2,
         xaxis.col='blue', xaxis.col.axis="blue", yaxis.col='green', yaxis.cex.axis=2,
         yaxis.at=c(0,0.5,0.8,0.85,0.9,1), yaxis.las=1, xaxis.lwd=2, yaxis.lwd=3,
         yaxis.col.axis="orange", cex.lab=2, cex.main=2)
}

test_6 <- function() {
    # create a simple prediction object
    library(ROCR)
    data(ROCR.simple)
    pred <- prediction(ROCR.simple$predictions,ROCR.simple$labels)
    pred
}

print("Running test_1")
test_1()

print("Running test_2")
test_2()

print("Running test_3")
test_3()

print("Running test_4")
test_4()

print("Running test_5")
test_5()

print("Running test_6")
test_6()

