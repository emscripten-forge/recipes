# remove all shared zlib instances
rm $PREFIX/lib/libz.so* || true


# remove BiocParallel,  from DESCRIPTION to avoid it being pulled in as a dependency, which causes issues with the build
sed -i.bak 's/BiocParallel, //g' DESCRIPTION
rm -f DESCRIPTION.bak 


# remove importFrom(BiocParallel, bplapply) from NAMESPACE to avoid it being pulled in as a dependency, which causes issues with the build
sed -i.bak 's/importFrom(BiocParallel, bplapply)//g' NAMESPACE
rm -f NAMESPACE.bak 

# replace bplapply with lapply in R/methods-BamViews.R
sed -i.bak 's/bplapply/lapply/g' R/methods-BamViews.R
rm -f R/methods-BamViews.R.bak

$R CMD INSTALL $R_ARGS .