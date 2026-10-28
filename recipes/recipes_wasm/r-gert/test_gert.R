print('Loading gert package')
library(gert)
print('... gert package loaded successfully')

test_1 <- function() {
    cfg <- libgit2_config()
    print(cfg)
    stopifnot(is.list(cfg) || is.data.frame(cfg) || length(cfg) > 0)
}

test_2 <- function() {
    tmp <- tempfile("gert-repo-")
    dir.create(tmp)
    git_init(path = tmp)
    stopifnot(dir.exists(file.path(tmp, ".git")) || file.exists(file.path(tmp, ".git")))
    info <- git_info(repo = tmp)
    print(info)
}

print("Running test_1")
test_1()

print("Running test_2")
test_2()
