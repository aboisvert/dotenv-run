import std/[unittest, tables, strtabs]
import dotenvrun/parse

test "parses basic assignment":
  let t = parseDotenv("FOO=bar\n")
  check t["FOO"] == "bar"

test "parses export prefix":
  let t = parseDotenv("export FOO=bar\n")
  check t["FOO"] == "bar"

test "parses double quotes and escapes":
  let t = parseDotenv("FOO=\"line\\none\"\n")
  check t["FOO"] == "line\none"

test "parses colon separator":
  let t = parseDotenv("FOO: bar\n")
  check t["FOO"] == "bar"

test "skips comments and blanks":
  let t = parseDotenv("# comment\n\nBAR=baz\n")
  check t.len == 1
  check t["BAR"] == "baz"

test "populate respects override":
  var env = newStringTable()
  env["A"] = "old"
  let parsed = parseDotenv("A=new\nB=two\n")
  let r = populateEnv(env, parsed, false)
  check env["A"] == "old"
  check env["B"] == "two"
  check r.populated.len == 1
  discard populateEnv(env, parsed, true)
  check env["A"] == "new"
