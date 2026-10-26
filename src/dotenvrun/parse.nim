## Parse and apply dotenv file contents (classic dotenv grammar).

import std/[os, strutils, tables, strtabs]

type PopulateResult* = object
  populated*: Table[string, string]

func isWhitespace(c: char): bool =
  c == ' ' or c == '\t' or (c >= '\9' and c <= '\r')

func isKeyChar(c: char): bool =
  c.isDigit or c.isAlphaAscii or c == '-' or c == '.' or c == '_'

func normalizeLineEndings(s: string): string =
  result = s
  result = result.replace("\r\n", "\n")
  result = result.replace("\r", "\n")

func unescapeDoubleQuotes(value: string): string =
  result = value
  result = result.replace("\\n", "\n")
  result = result.replace("\\r", "\r")

func parseDotenv*(src: string): Table[string, string] =
  ## Parse `src` into key/value pairs. Invalid lines are skipped.
  result = initTable[string, string]()
  let lines = normalizeLineEndings(src)
  var i = 0
  let n = lines.len
  while i < n:
    while i < n and isWhitespace(lines[i]):
      inc i
    if i >= n:
      break
    if lines[i] == '#':
      while i < n and lines[i] != '\n':
        inc i
      continue
    var exportEnd = -1
    if i + 6 < n and lines[i .. i + 5] == "export":
      let nc = lines[i + 6]
      if isWhitespace(nc):
        var next = i + 7
        while next < n and isWhitespace(lines[next]):
          inc next
        if next < n and isKeyChar(lines[next]):
          exportEnd = i + 6
          i = next
    let keyStart = i
    while i < n and isKeyChar(lines[i]):
      inc i
    if i == keyStart:
      while i < n and lines[i] != '\n':
        inc i
      continue
    let key = lines[keyStart ..< i]
    let keyEnd = i
    var stop = if i < n: lines[i] else: '\0'
    if isWhitespace(stop):
      while i < n and isWhitespace(lines[i]):
        inc i
      stop = if i < n: lines[i] else: '\0'
    if stop == '=':
      inc i
    elif stop == ':' and i == keyEnd and i + 1 < n and
        isWhitespace(lines[i + 1]):
      i += 2
    else:
      i = if exportEnd == -1: keyEnd else: exportEnd
      while i < n and lines[i] != '\n':
        inc i
      continue
    let rawStart = i
    var quoteStart = i
    while quoteStart < n and isWhitespace(lines[quoteStart]):
      inc quoteStart
    let quote = if quoteStart < n: lines[quoteStart] else: '\0'
    var value = ""
    var quoted = false
    if quote == '\'' or quote == '"' or quote == '`':
      let quoteChar = quote
      var j = lines.find(quoteChar, quoteStart + 1)
      var closingQuote = -1
      var closingEnd = -1
      while j != -1:
        let escaped = j > 0 and lines[j - 1] == '\\'
        var pos = j + 1
        while pos < n and lines[pos] != '\n' and isWhitespace(lines[pos]):
          inc pos
        if pos == n or lines[pos] == '\n' or lines[pos] == '#':
          closingQuote = j
          closingEnd = pos
        if not escaped:
          break
        j = lines.find(quoteChar, j + 1)
      if closingQuote != -1:
        value = lines[quoteStart + 1 ..< closingQuote]
        i = closingEnd
        if i < n and lines[i] == '#':
          while i < n and lines[i] != '\n':
            inc i
        quoted = true
    if not quoted:
      var nl = lines.find('\n', rawStart)
      if nl == -1:
        nl = n
      var hash = rawStart
      while hash < nl and lines[hash] != '#':
        inc hash
      var start = rawStart
      var endPos = hash
      while start < endPos and isWhitespace(lines[start]):
        inc start
      while endPos > start and isWhitespace(lines[endPos - 1]):
        dec endPos
      let first = if start < endPos: lines[start] else: '\0'
      value = lines[start ..< endPos]
      if endPos - start >= 2 and (first == '\'' or first == '"' or first == '`') and
          lines[endPos - 1] == first:
        value = lines[start + 1 ..< endPos - 1]
      i = hash
      if hash < nl:
        while i < n and lines[i] != '\n':
          inc i
    if quote == '"' and (quoted or quoteStart < i) and '\\' in value:
      value = unescapeDoubleQuotes(value)
    result[key] = value

proc populateEnv*(env: var StringTableRef; parsed: Table[string, string];
    override: bool): PopulateResult {.raises: [].} =
  ## Apply `parsed` to `env`. Existing keys are kept unless `override` is true.
  var applied = initTable[string, string]()
  for key, val in parsed:
    if key in env:
      if override:
        env[key] = val
        applied[key] = val
    else:
      env[key] = val
      applied[key] = val
  PopulateResult(populated: applied)

proc loadDotenvFile*(path: string; override: bool;
    env: var StringTableRef): (PopulateResult, bool) {.raises: [IOError].} =
  ## Read `path` and populate `env`. Returns populated keys and whether read succeeded.
  if not fileExists(path):
    return (PopulateResult(populated: initTable[string, string]()), false)
  let content = readFile(path)
  let parsed = parseDotenv(content)
  let populated = populateEnv(env, parsed, override)
  (populated, true)
