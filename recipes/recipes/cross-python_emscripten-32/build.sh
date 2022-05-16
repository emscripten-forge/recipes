mkdir -p ${PREFIX}/etc/conda/activate.d
mkdir -p ${PREFIX}/etc/conda/deactivate.d

cp "${RECIPE_DIR}"/_sysconfigdata__emscripten_.py ${PREFIX}/etc/conda/_sysconfigdata__emscripten_.py

cp "${RECIPE_DIR}"/activate-cross-python.sh ${PREFIX}/etc/conda/activate.d/activate_z-${PKG_NAME}.sh
cp "${RECIPE_DIR}"/deactivate-cross-python.sh ${PREFIX}/etc/conda/deactivate.d/deactivate_z-${PKG_NAME}.sh
