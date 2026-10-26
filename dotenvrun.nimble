version       = "0.1.1"
author        = "Alex Boisvert"
description   = "Run commands with environment variables loaded from .env files"
license       = "MIT"
srcDir        = "src"
bin           = @["dotenvrun"]
installExt    = @["nim"]

namedBin["dotenvrun"] = "dotenv-run"

requires "nim >= 2.2.0"

task tests, "run all tests":
  exec "nimble test"
