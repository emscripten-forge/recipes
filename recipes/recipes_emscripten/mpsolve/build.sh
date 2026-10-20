#!/usr/bin/env bash
set -euxo pipefail

# Match Bison's parser calls to the reentrant Flex scanner ABI.
YACC_PARSER=src/libmps/monomial/yacc-parser.y

sed -i \
  -e '/^[[:space:]]*%lex-param[[:space:]]*{[[:space:]]*void[[:space:]]*\*[[:space:]]*data[[:space:]]*}[[:space:]]*$/d' \
  -e 's|^[[:space:]]*extern int yylex(void \* yylval, void \* scanner, void \* data);|  extern int yylex(YYSTYPE * yylval, void * scanner);|' \
  -e 's|^[[:space:]]*extern int yyerror(void\*,void\*,const char\*);|  extern void yyerror(void*,void*,const char*);|' \
  "$YACC_PARSER"

! grep -qE '^[[:space:]]*%lex-param[[:space:]]*{[[:space:]]*void[[:space:]]*\*[[:space:]]*data[[:space:]]*}' \
  "$YACC_PARSER"
grep -Fq 'extern int yylex(YYSTYPE * yylval, void * scanner);' \
  "$YACC_PARSER"
grep -Fq 'extern void yyerror(void*,void*,const char*);' \
  "$YACC_PARSER"

# Force regeneration from the corrected grammar instead of compiling the
# incompatible parser files.
rm -f \
  src/libmps/monomial/yacc-parser.c \
  src/libmps/monomial/yacc-parser.h

export CPPFLAGS="-I${PREFIX}/include"
export LDFLAGS="-L${PREFIX}/lib"
export CXXFLAGS="-std=c++11"
export CFLAGS="-Wno-implicit-function-declaration"
export YACC="bison -y"

disable_examples=xyes emconfigure ./configure \
    --build=i686-pc-linux-gnu \
    --host=wasm32-unknown-emscripten \
    --disable-shared \
    --enable-static \
    --disable-examples \
    --prefix="${PREFIX}"

emmake make -j8
emmake make install

cp src/mpsolve/mpsolve.wasm "${PREFIX}/bin/"
