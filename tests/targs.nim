import std/unittest
import dotenvrun/args

test "default env path":
  let a = parseArgv(@[])
  check a.envPaths == @[".env"]

test "double dash passes flags to command":
  let a = parseArgv(@["-e", ".env", "--", "cmd", "--verbose"])
  check a.command == @["cmd", "--verbose"]

test "cascade with environment":
  let paths = buildCascadePaths(@[".env"], true, "test")
  check paths == @[".env.test.local", ".env.local", ".env.test", ".env"]

test "cascade conflicts detected via flags":
  let a = parseArgv(@["-c", "-o"])
  check a.cascade
  check a.override

test "no expand flag":
  let a = parseArgv(@["--no-expand", "echo"])
  check not a.expand

test "quiet false forms":
  let a = parseArgv(@["--quiet=false"])
  check not a.quiet
  let b = parseArgv(@["-q", "false"])
  check not b.quiet

test "validate cmd variable":
  let (k, v) = validateCmdVariable("FOO=bar")
  check k == "FOO"
  check v == "bar"

test "invalid cmd variable":
  var raised = false
  try:
    discard validateCmdVariable("bad")
  except ValueError:
    raised = true
  check raised
