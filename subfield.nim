import macros

type
  DotField = object
    parents: seq[NimNode]
    symbol: NimNode

iterator findSyms(obj: NimNode): NimNode =
  ## Iterate recursively through the symbols
  ## attached to the object using a stack
  var stack: seq[NimNode] = @[]
  stack.add(obj)

  while stack.len() != 0:
    let n = stack.pop()
    if n.kind == nnkSym:
      yield n
    else:
      for c in n.children:
        stack.insert(c, 0)

proc findFields(obj: NimNode): seq[NimNode] {. compileTime .} =
  # ObjectTy
  #   Empty
  #   RecList
  #     Sym "name"
  #     Sym "surname"
  #     Sym "age"
  result = @[]

  var recList: NimNode

  var tp = obj.getType()

  if tp.kind == nnkBracketExpr:
    # This is a ref object:
    #
    # BracketExpr
    #   Sym "ref"
    #   Sym "A:ObjectType" <- getType on this node
    #
    # A:ObjectType <- then getType on this to get the actual A object type
    #
    tp = obj.getType()[1].getType()

  # nnkRecList is the "Record List" or field list of the object
  recList = tp.findChild(it.kind == nnkRecList)

  if recList.kind != nnkNilLit:
    for sym in recList.findSyms():
      result.add(sym)

proc isNil(dotField: DotField): bool =
  ## Check if our custom field object is nil
  return dotField.parents.isNil and dotField.symbol.isNil

proc getNestedField(obj: NimNode, field: NimNode): DotField{.compileTime.} =
  ## Get the nested field iteratively using a stack
  var stack: seq[DotField] = @[DotField(parents: @[], symbol: obj)]

  var foundField: DotField
  let fieldRep = $field

  while stack.len() > 0 and foundField.isNil():
    # Pop an obj off the stack
    let dotField = stack[^1]
    stack.delete(stack.len - 1)

    var
      parents = dotField.parents
      currObj = dotField.symbol

    # Put the current symbol in the parents
    # of the next symbol
    parents.add(currObj)

    for sym in findFields(currObj):
      let newDotField = DotField(parents: parents, symbol: sym)
      if $sym.toStrLit() == fieldRep:
        # We've found our field!
        foundField = newDotField
        break
      else:
        # Haven't found it yet, keep iterating
        stack.add(newDotField)

  return foundField

proc transformToDotExpr(foundField: DotField): NimNode =
  ## Transform the found field into a dot expression.
  ##
  ## DotField(parents: @[a, b], symbol: c)
  ##
  ## turns into:
  ##
  ## a.b.c
  ##

  result = newNimNode(nnkDotExpr)

  # We basically want to turn DotField into an expression,
  # so iterate the parents and create a new dot expression
  # every 2 parents
  for i in 0 ..< foundField.parents.len():
    if result.len() == 2:
      result = newDotExpr(result, foundField.parents[i])
    else:
      result.add(foundField.parents[i])

  # If the dot expression has 2 children, it means
  # it's already a full dot expression, so create a new
  # one with the last symbol as the field being accessed
  if result.len() == 2:
    result = newDotExpr(result, foundField.symbol)
  else:
    # otherwise, the dot expression has one free space,
    # so just add the last symbol to it
    result.add(foundField.symbol)

macro `.`*(obj: typed, field: untyped): untyped =
  ## The anonymous field macro. This allows an object of structure
  ## a.b.c.d to access all subfields in one `dot` call. To call `d`, this
  ## macro allows simply to reference it via `a.d`
  ##
  ## called as `a.d`

  let foundField = getNestedField(obj, field)

  if not isNil(foundField):
    result = transformToDotExpr(foundField)
  else:
    # Get the original call
    result = callsite()

    if result.kind == nnkCall:
      # If this is a proc or method call, change it
      # to a proc call syntax because we don't want
      # infinite recursion on the macro call
      #
      # objName.procName()
      #
      # Call
      #   Ident !"."
      #   Sym "objName" <- this is our object
      #   StrLit procName <- this is our proc
      #
      result = newCall(ident($result[2]), result[1])
