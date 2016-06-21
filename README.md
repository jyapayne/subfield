# subfield
A sub-field accessor macro for the Nim programming language. This lets you access nested fields within a Nim object or ref object.

# Installation

```bash
nimble install subfield
```

#Usage

```nim
import subfield

type
  C = object
    y: int
  B = object
    x: int
    c: C
  A = ref object
    b: B

var c = C(y: 0)
var b = B(x: 5, c: c)
var a = A(b: b)

echo a.x
echo a.y

# Prints:
#  5
#  0
```
