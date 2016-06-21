import einheit
import subfield

testSuite SubFieldTests:
  method testOneLevel() =

    type
      C = object
        x: int
      B = object
        c: C
      A = object
        b: B

    var c = C(x: 20)
    var b = B(c: c)
    var a = A(b: b)

    self.check compiles(a.x)
    self.check a.x == 20

  method testTwoLevels() =
    type
      D = object
        y: int
      C = object
        d: D
      B = object
        c: C
      A = object
        b: B

    var d = D(y: 200)
    var c = C(d: d)
    var b = B(c: c)
    var a = A(b: b)

    self.check compiles(a.y)
    self.check a.y == 200

  method testBranch() =
    type
      D = object
        y: int
      C = object
        x: int
      B = object
        c: C
        d: D
      A = object
        b: B

    var d = D(y: 200)
    var c = C(x: 19)
    var b = B(c: c, d: d)
    var a = A(b: b)

    self.check compiles(a.y)
    self.check a.y == 200

    self.check compiles(a.x)
    self.check a.x == 19

