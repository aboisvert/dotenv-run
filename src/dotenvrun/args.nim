## Minimist-compatible argv parsing for dotenv-run.

import std/[strutils, sequtils]

type CliArgs* = object
  help*: bool
  debug*: bool
  quiet*: bool
  expand*: bool
  override*: bool
  cascade*: bool
  cascadeEnv*: string
  envPaths*: seq[string]
  cmdVarRaw*: seq[string]
  printVar*: string
  command*: seq[string]

proc parseArgv*(argv: openArray[string]): CliArgs {.raises: [].} =
  var cli = CliArgs(
    quiet: true,
    expand: true,
    envPaths: @[],
    cmdVarRaw: @[],
    command: @[],
  )
  var dashDash = -1
  for j, a in argv:
    if a == "--":
      dashDash = j
      break
  let flagArgs = if dashDash >= 0: @argv[0 ..< dashDash] else: argv.toSeq
  let afterDash =
    if dashDash >= 0: @argv[dashDash + 1 .. argv.high] else: newSeq[string]()
  var i = 0
  while i < flagArgs.len:
    let arg = flagArgs[i]
    if arg == "--help":
      cli.help = true
    elif arg == "--debug":
      cli.debug = true
    elif arg == "--no-expand":
      cli.expand = false
    elif arg == "--override" or arg == "-o":
      cli.override = true
    elif arg.startsWith("--quiet="):
      cli.quiet = arg["--quiet=".len .. ^1] != "false"
    elif arg == "--quiet":
      if i + 1 < flagArgs.len and flagArgs[i + 1] == "false":
        cli.quiet = false
        inc i
    elif arg.startsWith("-q="):
      cli.quiet = arg["-q=".len .. ^1] != "false"
    elif arg == "-q":
      if i + 1 < flagArgs.len and flagArgs[i + 1] == "false":
        cli.quiet = false
        inc i
    elif arg == "-e":
      inc i
      if i < flagArgs.len:
        cli.envPaths.add flagArgs[i]
    elif arg.startsWith("-e="):
      cli.envPaths.add arg[3 .. ^1]
    elif arg == "-v":
      inc i
      if i < flagArgs.len:
        cli.cmdVarRaw.add flagArgs[i]
    elif arg.startsWith("-v="):
      cli.cmdVarRaw.add arg[3 .. ^1]
    elif arg == "-p":
      inc i
      if i < flagArgs.len:
        cli.printVar = flagArgs[i]
    elif arg == "-c":
      cli.cascade = true
      if i + 1 < flagArgs.len and not flagArgs[i + 1].startsWith("-") and
          flagArgs[i + 1] != "-e" and flagArgs[i + 1] != "-v" and
          flagArgs[i + 1] != "-p":
        inc i
        cli.cascadeEnv = flagArgs[i]
    elif arg.startsWith("-c") and arg.len > 2:
      cli.cascade = true
      cli.cascadeEnv = arg[2 .. ^1]
    elif arg.startsWith("--") and '=' in arg:
      let eq = arg.find('=')
      let key = arg[2 ..< eq]
      let value = arg[eq + 1 .. ^1]
      if key == "quiet":
        cli.quiet = value != "false"
    elif arg.startsWith("-") and arg.len > 1 and arg != "-":
      var j = 1
      while j < arg.len:
        case arg[j]
        of 'o':
          cli.override = true
        of 'q':
          cli.quiet = true
        of 'c':
          cli.cascade = true
          if j + 1 < arg.len:
            cli.cascadeEnv = arg[j + 1 .. ^1]
            j = arg.high
        of 'e':
          if j + 1 < arg.len:
            cli.envPaths.add arg[j + 1 .. ^1]
            j = arg.high
          else:
            inc i
            if i < flagArgs.len:
              cli.envPaths.add flagArgs[i]
        of 'v':
          if j + 1 < arg.len and '=' in arg[j + 1 .. ^1]:
            cli.cmdVarRaw.add arg[j + 1 .. ^1]
            j = arg.high
          else:
            inc i
            if i < flagArgs.len:
              cli.cmdVarRaw.add flagArgs[i]
        of 'p':
          inc i
          if i < flagArgs.len:
            cli.printVar = flagArgs[i]
        else:
          discard
        inc j
    elif not arg.startsWith("-"):
      cli.command.add arg
    inc i
  for item in afterDash:
    cli.command.add item
  if cli.envPaths.len == 0:
    cli.envPaths = @[".env"]
  cli

proc validateCmdVariable*(param: string): (string, string) {.raises: [ValueError].} =
  let eq = param.find('=')
  if eq < 0:
    raise newException(ValueError, "invalid")
  let key = param[0 ..< eq]
  if key.len == 0 or not key.allIt(it.isAlphaNumeric or it == '_'):
    raise newException(ValueError, "invalid")
  let val = param[eq + 1 .. ^1]
  if val.len == 0:
    raise newException(ValueError, "invalid")
  (key, val)

proc buildCascadePaths*(basePaths: seq[string]; cascade: bool;
    cascadeEnv: string): seq[string] =
  if not cascade:
    return basePaths
  var cascadePaths: seq[string] = @[]
  for path in basePaths:
    if cascadeEnv.len > 0:
      cascadePaths.add path & "." & cascadeEnv & ".local"
      cascadePaths.add path & ".local"
      cascadePaths.add path & "." & cascadeEnv
      cascadePaths.add path
    else:
      cascadePaths.add path & ".local"
      cascadePaths.add path
  cascadePaths
