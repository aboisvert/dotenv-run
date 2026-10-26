import std/os
import dotenvrun/run

export run

when isMainModule:
  var args: seq[string] = @[]
  for i in 1 .. paramCount():
    args.add paramStr(i)
  quit runCli(args).int
