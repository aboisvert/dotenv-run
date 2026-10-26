## CLI runner: load env, expand, spawn child.

import std/[os, strutils, tables, sequtils, osproc, strtabs]
import ./args
import ./parse
import ./expand

const NimblePkgVersion {.strdefine.} = "0.1.0"

proc pkgVersion(): string =
  if NimblePkgVersion.len > 0:
    NimblePkgVersion
  else:
    "0.1.0"

proc printHelp() =
  echo [
    "dotenv-run v" & pkgVersion(),
    "https://github.com/entropitor/dotenv-cli",
    "",
    "Usage: dotenv-run [--help] [--debug] [--quiet=false] [-e] [-v =] [-p] [-c [environment]] [--no-expand] [-- command]",
    "  --help                          print help",
    "  --debug                         output the files that would be processed but don't actually parse them or run the `command`",
    "  --quiet, -q                     suppress debug output from dotenv (default: true)",
    "  -e                              parses the file as a `.env` file and adds the variables to the environment",
    "  -e                              multiple -e flags are allowed",
    "  -v =                            put variable into environment using value",
    "  -v =                            multiple -v flags are allowed",
    "  -p                              print value of to the console. If you specify this, you do not have to specify a `command`",
    "  -c [environment]               support cascading env variables from `.env`, `.env.<environment>`, `.env.local`, `.env.<environment>.local` files",
    "  --no-expand                     skip variable expansion",
    "  -o, --override                  override system variables. Cannot be used along with cascade (-c).",
    "  command                         `command` is the actual command you want to run. Best practice is to precede this command with ` -- `. Everything after `--` is considered to be your command. So any flags will not be parsed by this tool but be passed to your command. If you do not do it, this tool will strip those flags",
  ].join("\n")

proc envFileShortPath(path: string): string =
  let cwd = getCurrentDir()
  if path.isAbsolute:
    try:
      relativePath(cwd, path)
    except ValueError:
      path
  else:
    path

proc debugPrintPaths(paths: seq[string]) =
  var parts: seq[string] = @[]
  for p in paths:
    parts.add "'" & p & "'"
  echo "[" & parts.join(", ") & "]"

proc debugPrintVars(vars: Table[string, string]) =
  var parts: seq[string] = @[]
  for k, v in vars.pairs:
    parts.add k & ": '" & v & "'"
  echo "{" & parts.join(", ") & "}"

proc runChild(command: seq[string]): int {.raises: [OSError, IOError, ValueError].} =
  if command.len == 0:
    return 1
  let exe = command[0]
  let args = if command.len > 1: command[1 .. ^1] else: @[]
  var p = startProcess(
    exe,
    args = args,
    options = {poUsePath, poParentStreams},
  )
  let exitCode = waitForExit(p)
  close(p)
  exitCode

proc runCli*(argv: openArray[string]): int {.raises: [OSError, ValueError, IOError].} =
  let cli = parseArgv(argv)
  if cli.help:
    printHelp()
    return 0
  if cli.cascade and cli.override:
    stderr.writeLine(
      "Invalid arguments. Cascading env variables conflicts with overrides.")
    return 1
  var cmdVars = initTable[string, string]()
  for raw in cli.cmdVarRaw:
    try:
      let (k, v) = validateCmdVariable(raw)
      cmdVars[k] = v
    except ValueError:
      stderr.writeLine(
        "Invalid variable name. Expected variable in format '-v variable=value', but got: `-v " &
        raw & "`.")
      return 1
  let paths = buildCascadePaths(cli.envPaths, cli.cascade, cli.cascadeEnv).mapIt(
    absolutePath(it))
  if cli.debug:
    debugPrintPaths paths
    debugPrintVars cmdVars
    return 0
  var env = newStringTable()
  for k, v in envPairs():
    env[k] = v
  for path in paths:
    let (populated, ok) = loadDotenvFile(path, cli.override, env)
    if ok and not cli.quiet:
      stderr.writeLine(
        "◇ injected env (" & $populated.populated.len & ") from " &
        envFileShortPath(path))
  if cli.expand:
    expandEnv(env)
  for k, v in cmdVars.pairs:
    env[k] = v
  for k, v in env.pairs:
    putEnv(k, v)
  if cli.printVar.len > 0:
    let value = getEnv(cli.printVar)
    if value.len > 0:
      echo value
    else:
      echo ""
    return 0
  if cli.command.len == 0:
    printHelp()
    return 1
  try:
    return runChild(cli.command)
  except OSError as e:
    stderr.writeLine(e.msg)
    return 1
