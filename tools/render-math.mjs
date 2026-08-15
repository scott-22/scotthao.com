import * as std from 'qjs:std'
import katex from '../katex/katex.mjs'

std.out.puts(
  katex.renderToString(std.in.readAsString().trim(), {
    displayMode: scriptArgs[1] === 'display',
    throwOnError: true,
    strict: 'warn',
  }),
)
