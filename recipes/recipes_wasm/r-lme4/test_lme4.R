print('Loading lme4 package')
library(lme4)
print('... lme4 package loaded successfully')

test_1 <- function() {
    library(lme4)
    data(sleepstudy)
    fit <- lmer(Reaction ~ Days + (1 | Subject), data = sleepstudy)
    print(summary(fit))
    stopifnot(inherits(fit, "lmerMod"))
}

print("Running test_1")
test_1()
