# Package

version       = "0.1.0"
author        = "Joey Payne"
description   = "A sub-field accessor macro for the Nim programming language."
license       = "MIT"

bin = @["subfield"]

# Dependencies

requires "nim >= 0.14.0", "einheit >= 0.1.6"

task tests, "run all tests":
  exec "nim c -r tests/tests.nim"
