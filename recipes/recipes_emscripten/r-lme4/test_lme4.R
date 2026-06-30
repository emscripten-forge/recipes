library(lme4)

data(sleepstudy)

fit <- lmer(Reaction ~ Days + (1 | Subject), data = sleepstudy)
summary(fit)