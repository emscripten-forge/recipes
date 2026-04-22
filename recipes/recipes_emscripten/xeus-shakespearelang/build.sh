#!/bin/bash


SIDE_PATH=$PREFIX/lib/python$PY_VER/site-packages
KERNEL_DIR=$PREFIX/share/jupyter/kernels/xeus_shakespearelang

echo "PREFIX: $PREFIX"
echo "SIDE_PATH: $SIDE_PATH"
echo "KERNEL_DIR: $KERNEL_DIR"

# copy 
mkdir -p $KERNEL_DIR
cp -r examples/xeus_shakespearelang/kernelspec/xeus_shakespearelang/kernel.json.in  $KERNEL_DIR/kernel.json

if [[ "$OSTYPE" == "darwin"* ]]; then
  # macOS / BSD
  sed -i '' "s|@XEUS_PYWRAP_KERNELSPEC_PATH@|/bin/|g" "$KERNEL_DIR/kernel.json"
else
  # Linux / GNU
  sed -i "s|@XEUS_PYWRAP_KERNELSPEC_PATH@|/bin/|g" "$KERNEL_DIR/kernel.json"
fi


# show $KERNEL_DIR/kernel.json 
cat $KERNEL_DIR/kernel.json

# copy module
cp -r  examples/xeus_shakespearelang/module/* $SIDE_PATH/xeus_shakespearelang