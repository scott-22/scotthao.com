#!/bin/sh
set -eu

cd "$(dirname "$0")/.."

# Keep in sync with `render-code` in templates/utils.lisp.
STYLE=github
PREFIX=hl-

./chroma --style "$STYLE" --html --html-styles --html-prefix "$PREFIX" < /dev/null \
    | sed -e '/^\/\* Background \*\//d' -e '/^\/\* PreWrapper \*\//d' \
    > public/chroma.css

rm -rf public/katex
mkdir -p public/katex/fonts
cp katex/katex.min.css public/katex/katex.min.css
cp katex/fonts/*.woff2 public/katex/fonts/
