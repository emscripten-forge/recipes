#!/bin/bash


SIDE_PATH=$PREFIX/lib/python$PY_VER/site-packages
KERNEL_DIR=$PREFIX/share/jupyter/kernels/xeus_shakespearelang



# copy 
mkdir -p $KERNEL_DIR
cp -r examples/xeus_shakespearelang/kernelspec/xeus_shakespearelang/kernel.json.in  $KERNEL_DIR/kernel.json
cp examples/xeus_shakespearelang/kernelspec/xeus_shakespearelang/*.png $KERNEL_DIR/
if [[ "$OSTYPE" == "darwin"* ]]; then
  # macOS / BSD - note the space after -i ''
  sed -i '' "s|@XEUS_PYWRAP_KERNELSPEC_PATH@|$PREFIX/bin/|g" "$KERNEL_DIR/kernel.json"
else
  # Linux / GNU
  sed -i "s|@XEUS_PYWRAP_KERNELSPEC_PATH@|$PREFIX/bin/|g" "$KERNEL_DIR/kernel.json"
fi

# show $KERNEL_DIR/kernel.json 
cat $KERNEL_DIR/kernel.json

# copy module
cp -r  examples/xeus_shakespearelang/module/* $SIDE_PATH/xeus_shakespearelang
