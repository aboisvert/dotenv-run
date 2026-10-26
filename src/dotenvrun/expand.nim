## Variable expansion (dotenv-expand 12.0.3 semantics).

import std/[options, sequtils, strutils, tables, sets, strtabs]

func resolveEscapeSequences(value: string): string =
  result = value
  result = result.replace("\\$", "$")

proc findNextExpansion(s: string; start: int): Option[(int, int, string, string)] =
  ## Returns (start, endExclusive, bracedExpr, unbracedExpr) or none.
  var i = start
  while i < s.len:
    if i > 0 and s[i - 1] == '\\':
      inc i
      continue
    if i + 1 < s.len and s[i] == '$' and s[i + 1] == '{':
      var j = i + 2
      while j < s.len and s[j] != '}':
        inc j
      if j < s.len:
        return some((i, j + 1, s[i + 2 ..< j], ""))
      inc i
      continue
    if s[i] == '$' and i + 1 < s.len:
      let c = s[i + 1]
      if c.isAlphaAscii or c == '_':
        var j = i + 1
        while j < s.len:
          let ch = s[j]
          if ch.isAlphaAscii or ch.isDigit or ch == '_':
            inc j
          else:
            break
        return some((i, j, "", s[i + 1 ..< j]))
    inc i
  none((int, int, string, string))

func expandValue(value: string; processEnv: StringTableRef;
    runningParsed: Table[string, string]): string =
  var env = runningParsed
  for k, v in processEnv.pairs:
    env[k] = v
  var expanded = value
  var seen = initHashSet[string]()
  block expandLoop:
    while true:
      let found = findNextExpansion(expanded, 0)
      if found.isNone:
        break
      let (matchStart, matchEnd, braced, unbraced) = found.get()
      seen.incl(expanded)
      let expression = if braced.len > 0: braced else: unbraced
      var splitter = ""
      var opPos = -1
      for op in [":+", "+", ":-", "-"]:
        opPos = expression.find(op)
        if opPos >= 0:
          splitter = op
          break
      var key = expression
      var defaultValue = ""
      var varValue = ""
      if splitter.len > 0:
        key = expression[0 ..< opPos]
        defaultValue = expression[opPos + splitter.len .. ^1]
        if splitter in [":+", "+"]:
          if key in env and env[key].len > 0:
            discard
          else:
            defaultValue = ""
          varValue = ""
        else:
          if key in env:
            varValue = env[key]
      else:
        if key in env:
          varValue = env[key]
      var replacement = defaultValue
      if varValue.len > 0:
        if varValue in seen:
          replacement = defaultValue
        else:
          replacement = varValue
      expanded = expanded[0 ..< matchStart] & replacement & expanded[matchEnd .. ^1]
      if key in runningParsed and expanded == runningParsed[key]:
        break expandLoop
  expanded

proc expandEnv*(env: var StringTableRef) {.raises: [KeyError].} =
  ## Expand all values in `env` in place (progressive, key order from env).
  var runningParsed = initTable[string, string]()
  let keys = env.keys.toSeq
  for key in keys:
    let value = expandValue(env[key], env, runningParsed)
    let resolved = resolveEscapeSequences(value)
    env[key] = resolved
    runningParsed[key] = resolved
