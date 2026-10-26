version       = "0.1.0"
author        = "Alex Boisvert"
description   = "Run commands with environment variables loaded from .env files"
license       = "MIT"
srcDir        = "src"
bin           = @["dotenvrun"]
installExt    = @["nim"]

namedBin["dotenvrun"] = "dotenv-run"

requires "nim >= 2.2.0"
