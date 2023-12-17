import std/macros
import std/options
import std/sequtils
import std/sugar
import std/tables
import std/times

import opengl
import shady
import staticglfw
import vmath

export opengl
export shady
export staticglfw
export vmath


type
  DUniformPtr = Table[string, ptr float64] 
  FUniformPtr = Table[string, ptr float32]
  IUniformPtr = Table[string, ptr int32]
  UUniformPtr = Table[string, ptr uint32]
 
  UniformPtr* = object
    d: Option[DUniformPtr]
    f: Option[FUniformPtr]
    i: Option[IUniformPtr]
    u: Option[UUniformPtr]


proc newUniformPtr*(
  dUniformPtr: Option[DUniformPtr] = none(DUniformPtr),
  fUniformPtr: Option[FUniformPtr] = none(FUniformPtr),
  iUniformPtr: Option[IUniformPtr] = none(IUniformPtr),
  uUniformPtr: Option[UUniformPtr] = none(UUniformPtr)
): UniformPtr =
  UniformPtr(d: dUniformPtr, f: fUniformPtr, i: iUniformPtr, u: uUniformPtr)


const
  dTypeToUniformProc = {
    "float64": glUniform1dv,
    "Dvec2": glUniform2dv,
    "Dvec3": glUniform3dv,
    "Dvec4": glUniform4dv
  }.toTable()

  fTypeToUniformProc = {
    "float32": glUniform1fv,
    "Vec2": glUniform2fv,
    "Vec3": glUniform3fv,
    "Vec4": glUniform4fv
  }.toTable()

  iTypeToUniformProc = {
    "int32": glUniform1iv,
    "Ivec2": glUniform2iv,
    "Ivec3": glUniform3iv,
    "Ivec4": glUniform4iv
  }.toTable()

  uTypeToUniformProc = {
    "uint32": glUniform1uiv,
    "Uvec2": glUniform2uiv,
    "Uvec3": glUniform3uiv,
    "Uvec4": glUniform4uiv
  }.toTable()


proc vertexShaderBasic(
  gl_Position: var Vec4,
  position: Vec2
) =
  gl_Position = vec4(position.x, position.y, 0.0, 1.0)


proc checkError(shader: GLuint) =
  var code: GLint
  glGetShaderiv(shader, GL_COMPILE_STATUS, code.addr())

  if code.GLboolean == GL_TRUE:
    return

  var length: GLint = 0
  glGetShaderiv(shader, GL_INFO_LOG_LENGTH, length.addr())
  var log = newString(length.int)
  glGetShaderInfoLog(shader, length, nil, cstring(log))
  echo log


proc initializeWindow(
  size: static[tuple[width: int, height: int]],
  title: static[string],
  version: static[tuple[major: int, minor: int]]
): Window =
  const titlePrefix = "Morchella"

  windowHint(SAMPLES, 0)
  windowHint(CONTEXT_VERSION_MAJOR, version.major.cint())
  windowHint(CONTEXT_VERSION_MINOR, version.minor.cint())

  let window = createWindow(
    size.width.cint(),
    size.height.cint(),
    (titlePrefix & " - " & title & " - ").cstring(),
    nil,
    nil
  )
  window.makeContextCurrent()

  return window


proc fetchUniformsInner*(procNode: NimNode): seq[(string, string)] =
  ## Return list of Uniform fetched out of a shader proc implementation.
  ## procNode is assumed nnkSym (symbol),
  ## and topNode is assumed nnkProcDef (define of proc) or nnkFuncDef (define of func).

  let topNode = procNode.getImpl()
  echo $topNode.kind()
  var uniforms: seq[(string, string)] = @[]

  for node in topNode:
    case node.kind()
    of nnkSym:
      # Node that means a name of proc or func
      echo "  " & $node.kind() & ": " & $node
    of nnkFormalParams:
      # Node that means list of arguments
      echo "  " & $node.kind()
      for subNode in node:
        case subNode.kind()
        of nnkIdentDefs:
          # Node that means define of arguments
          echo "    " & $subNode.kind()
          case subNode[0].kind()
          of nnkSym:
            # Node that means a name of a argument
            echo "      " & $subNode[0].kind() & ": " & $subNode[0]
            case subNode[1].kind()
            of nnkBracketExpr:
              # Like a type of Uniform[Vec2]
              echo "      " & $subNode[1].kind()
              if $subNode[1][0] == "Uniform":
                echo "        " & $subNode[1][0].kind() & ": " & $subNode[1][0]
                echo "        " & $subNode[1][1].kind() & ": " & $subNode[1][1]
                let pair = ($subNode[0], $subNode[1][1])
                uniforms.add(pair)
            of nnkVarTy:
              # Like a type of var Vec2 (mutable argument)
              echo "      " & $subNode[1].kind()
              echo "        " & $subNode[1][0].kind() & ": " & $subNode[1][0]
            else:
              echo "      " & $subNode[1].kind()
          else:
            echo "      " & $subNode[0].kind()
            echo "      " & $subNode[1].kind()
        of nnkEmpty:
          echo "    " & $subNode.kind()
        else:
          echo "    " & $subNode.kind() & ": " & $subNode
    else:
      echo "  " & $node.kind()
  echo ""

  return uniforms


macro fetchUniforms*(shaderProc: typed): seq[(string, string)] =
  assert shaderProc.getImpl().kind() in {nnkFuncDef, nnkProcDef}
  newLit(fetchUniformsInner(shaderProc))


proc initialize*(
  size: static[tuple[width: int, height: int]],
  title: static[string],
  version: static[tuple[major: int, minor: int]],
  fragmentShader: tuple[text: string, uniforms: seq[(string, string)]]
): (Window, GLuint, seq[(string, string, GLuint)], float32) =
  if init() == 0:
    raise newException(Exception, "Failed to Initialize GLFW")

  var window = initializeWindow(size, title, version)

  when not defined(emscripten):
    loadExtensions()

  const
    exponent = 4
  var
    vertices: array[0 .. 11, float32] = [
      -1.0f, 1.0f,
      -1.0f, -1.0f,
      1.0f, -1.0f,
      -1.0f, 1.0f,
      1.0f, -1.0f,
      1.0f, 1.0f
    ]

  var vertexArrayId: GLuint
  glGenVertexArrays(1, vertexArrayId.addr())
  glBindVertexArray(vertexArrayId)

  var vertexBuffer: GLuint
  glGenBuffers(1, vertexBuffer.addr())
  glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer)
  glBufferData(GL_ARRAY_BUFFER, vertices.len * exponent, vertices[0].addr(), GL_STATIC_DRAW)

  const versionStr = $version.major & $version.minor & "0"

  var
    vertexShaderText = vertexShaderBasic.toGLSL(static versionStr)

  var
    vertexShaderProgram = glCreateShader(GL_VERTEX_SHADER)
    vertexShaderTextArray = allocCStringArray([vertexShaderText])
  glShaderSource(vertexShaderProgram, opengl.GLsizei(1), vertexShaderTextArray, nil)
  glCompileShader(vertexShaderProgram)
  checkError(vertexShaderProgram)
  echo vertexShaderText

  var
    fragmentShaderProgram = glCreateShader(GL_FRAGMENT_SHADER)
    fragmentShaderTextArray = allocCStringArray([fragmentShader.text])
  glShaderSource(fragmentShaderProgram, opengl.GLsizei(1), fragmentShaderTextArray, nil)
  glCompileShader(fragmentShaderProgram)
  checkError(fragmentShaderProgram)
  echo fragmentShader.text

  var program = glCreateProgram()
  glAttachShader(program, vertexShaderProgram)
  glAttachShader(program, fragmentShaderProgram)
  glLinkProgram(program)

  let positionLocation = opengl.GLuint(glGetAttribLocation(program, "position"))
  
  glVertexAttribPointer(
    positionLocation,
    opengl.GLint(2),
    cGL_FLOAT,
    GL_FALSE,
    opengl.GLsizei(0),
    nil
  )
  glEnableVertexAttribArray(positionLocation)

  let
    startTime = epochTime().float32()
    uniformLocations = fragmentShader.uniforms.map((uniform: (string, string)) => (
      uniform[0],
      uniform[1],
      opengl.GLuint(glGetUniformLocation(program, uniform[0].cstring()))
    )) 

  (window: window, program: program, uniformLocations: uniformLocations, startTime: startTime)


proc getResolution*(window: Window): array[0..1, float32] =
  var width, height: cint
  getFramebufferSize(window, width.addr(), height.addr())
  return [width.float32(), height.float32()]


proc getTime*(startTime: float32): float32 =
  return epochTime() - startTime


proc renderInner*(
  window: Window,
  program: GLuint,
  resolution: array[0..1, float32],
  uniformPtr: UniformPtr,
  uniformLocations: seq[(string, string, GLuint)]
) =
  glViewport(0, 0, resolution[0].GLsizei(), resolution[1].GLsizei())
  glClearColor(0, 0, 0, 1)
  glClear(GL_COLOR_BUFFER_BIT)

  glUseProgram(program)

  for (uniformName, uniformType, uniformLocation) in uniformLocations:
    let
      dUniformProc = dTypeToUniformProc.getOrDefault(uniformType, nil)
      fUniformProc = fTypeToUniformProc.getOrDefault(uniformType, nil)
      iUniformProc = iTypeToUniformProc.getOrDefault(uniformType, nil)
      uUniformProc = uTypeToUniformProc.getOrDefault(uniformType, nil)

    if not dUniformProc.isNil():
      let dUniformValuePtr = 
        if uniformPtr.d.isSome():
          uniformPtr.d.get().getOrDefault(uniformName, nil)
        else: nil
      assert not dUniformValuePtr.isNil()
      dUniformProc(uniformLocation.GLint, 1, dUniformValuePtr)
      continue

    if not fUniformProc.isNil():
      let fUniformValuePtr =
        if uniformPtr.f.isSome():
          uniformPtr.f.get().getOrDefault(uniformName, nil)
        else: nil
      assert not fUniformValuePtr.isNil()
      fUniformProc(uniformLocation.GLint, 1, fUniformValuePtr)
      continue

    if not iUniformProc.isNil():
      let iUniformValuePtr =
        if uniformPtr.i.isSome():
          uniformPtr.i.get().getOrDefault(uniformName, nil)
        else: nil
      assert not iUniformValuePtr.isNil()
      iUniformProc(uniformLocation.GLint, 1, iUniformValuePtr)
      continue

    if not uUniformProc.isNil():
      let uUniformValuePtr =
        if uniformPtr.u.isSome():
          uniformPtr.u.get().getOrDefault(uniformName, nil)
        else: nil
      assert not uUniformValuePtr.isNil()
      uUniformProc(uniformLocation.GLint, 1, uUniformValuePtr)
      continue

    raise newException(ValueError, "")

  glDrawArrays(GL_TRIANGLES, 0, 6)

  window.swapBuffers()


proc render*(
  self: tuple[
    window: Window,
    program: GLuint,
    uniformLocations: seq[(string, string, GLuint)],
    startTime: float32
  ]
): int =
  var
    resolution: array[0..1, float32]
    time: float32
  
  let fUniformPtr = {
    "resolution": resolution[0].addr(),
    "time": time.addr()
  }.toTable()

  while self.window.windowShouldClose() == 0:
    resolution = self.window.getResolution()
    time = getTime(self.startTime)

    renderInner(
      self.window,
      self.program,
      resolution,
      uniformPtr = newUniformPtr(funiformPtr = some(fUniformPtr)),
      uniformLocations = self.uniformLocations
    )

    pollEvents()
 
  return 0
