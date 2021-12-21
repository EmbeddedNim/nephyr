import macros

type
  cmtoken* = distinct string
  cminvtoken* = distinct pointer

macro CDefineToken*(name: varargs[untyped]): cmtoken =
  let tokenStr = newLit(name.repr)
  result = quote do:
      cmtoken(`tokenStr`)

macro CDeclartionInvoke*(defineName: untyped, name: varargs[untyped]) =
  ## Calls a C Defines Macro as a declaration
  ## Useful for C macros that define a struct or variable
  ## at the top level
  let macroInvokeName = newLit( defineName.repr & "(" & name.repr & ");")
  result = quote do:
    {.emit: `macroInvokeName`.}

macro CDefineExpression*(name: untyped, macroInvocation: untyped, retType: typedesc) =
  ## Defines a "variable" which is really a macro expression
  ## e.g.  CDefineExpression(DEVICE_NAME_ID, DEVICE_NAME_ID(Id)): int
  ## will define 
  let macroInvokeName = newLit( macroInvocation.repr )
  let rt = parseExpr(retType.repr)
  result = quote do:
    var `name` {.importc: `macroInvokeName`, global, noinit, nodecl.}: `rt`

macro CTOKEN*(macroInvocation: untyped): cminvtoken =
  let macroInvokeName = newLit( macroInvocation.repr )
  result = quote do:
      var mi {.importc: `macroInvokeName`, global, noinit, nodecl.}: cminvtoken
      mi

macro CM_PROC*(macroName: untyped, margs: untyped): untyped =
  echo "MCM_PROC:MN =",  macroName.treeRepr
  echo "MCM_PROC:ARGS =", margs.treeRepr
  echo "MARGS expand =", margs.expandMacros.treeRepr
  let mn = macroname.repr

  var label: string
  if margs.kind == nnkIdent:
    # assert margs.strVal == "tok"
    label = margs.strVal
  else:
    margs.expectKind(nnkCallStrLit)
    margs[0].expectKind(nnkIdent)
    margs[1].expectKind(nnkRStrLit)
    assert margs[0].strVal == "tok"
    label = margs[1].strVal

  echo "label: ", label
  let
    # label = margs[1].strVal
    mas = mn & "(" & label & ")"
    ma = newLit mas
  result = quote do:
      var mi2 {.importc: `ma`, global, nodecl, noinit.}: cminvtoken
      mi2

macro `tok`*(token: untyped): cminvtoken = 
  let nm: string = 
    if token.kind == nnkAccQuoted:
      token.expectKind({nnkAccQuoted, nnkRStrLit})
      token.expectLen(1)
      token[0].strVal
    elif token.kind == nnkRStrLit:
      token.strVal
    else:
      error("tok must be used like 'tok\"MYCTOKEN\"' or 'tok`MYCTOKEN`' ", token)
      raise newException(ValueError, "tok error")
  
  let mi = newLit(nm)
  result = quote do:
      var mi2 {.importc: `mi`, global, nodecl, noinit.}: cminvtoken
      mi2

macro CDefineDeclareVar*(name: untyped, macroRepr: untyped, retType: typedesc) =
  let macroInvokeName = newLit( macroRepr.repr )
  let rt = parseExpr(retType.repr)
  result = quote do:
    var myMacroVar {.importc: `macroInvokeName`, global, noinit, nodecl.}: `rt`
    var `name`* = myMacroVar
