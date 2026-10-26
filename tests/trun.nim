import std/[unittest, os, strutils]
import dotenvrun/run

test "debug does not require command":
  let code = runCli(@["--debug", "-e", ".env"])
  check code == 0

test "help without command exits 1":
  let code = runCli(@[])
  check code == 1

test "print env var from file":
  let dir = absolutePath("tests/fixtures/run")
  if not dirExists(dir):
    createDir(dir)
  let envPath = dir / ".env"
  writeFile(envPath, "PRINT_ME=hello\n")
  let prev = getCurrentDir()
  setCurrentDir(dir)
  try:
    let code = runCli(@["-p", "PRINT_ME"])
    check code == 0
  finally:
    setCurrentDir(prev)
    removeFile(envPath)

test "child exit code":
  let code = runCli(@["--", "sh", "-c", "exit 42"])
  check code == 42
