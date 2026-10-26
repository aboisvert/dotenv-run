import std/[unittest, strtabs]
import dotenvrun/expand

test "expands unbraced variable":
  var env = newStringTable()
  env["IP"] = "127.0.0.1"
  env["PORT"] = "1234"
  env["APP_URL"] = "http://${IP}:${PORT}"
  expandEnv(env)
  check env["APP_URL"] == "http://127.0.0.1:1234"

test "resolves escaped dollar":
  var env = newStringTable()
  env["X"] = "pas\\$word"
  expandEnv(env)
  check env["X"] == "pas$word"

test "default when missing":
  var env = newStringTable()
  env["MSG"] = "${MISSING:-fallback}"
  expandEnv(env)
  check env["MSG"] == "fallback"
