library(fs)

p <- path_temp("emforge-fs-check")
dir_create(p)
stopifnot(dir_exists(p))
dir_delete(p)
print(path_wd())
