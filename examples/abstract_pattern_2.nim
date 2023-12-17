import morchella


proc fragmentShaderAbstractPattern2Proc(
  gl_FragCoord: Vec4,
  resolution: Uniform[Vec2],
  time: Uniform[float32],
  pixelColor: var Vec4
) =
  var
    uv = (gl_FragCoord.xy * 2.0 - resolution.xy) / min(resolution.x, resolution.y)
    division = 16.0
    x = ceil(vec2(division) * sin(vec2(time))) / vec2(division) * sin(uv)
    y = dot(uv, x)
    z = abs(y)
    r = ceil((sin(time * z * 1.0) * sin(ceil(length(uv) * division) + 1.0 * sin(time)) + 1.0) *
        division) / division
    g = ceil((sin(time * z * 3.0) * sin(ceil(length(uv) * division) + 3.0 * sin(time)) + 1.0) *
        division) / division
    b = ceil((sin(time * z * 5.0) * sin(ceil(length(uv) * division) + 5.0 * sin(time)) + 1.0) *
        division) / division
  var color = vec3(r, g, b)
  pixelColor = vec4(color, 1.0)


proc play(): int =
  const
    version = (major: 4, minor: 5)
    versionStr = $version.major & $version.minor & "0"
 
  let
    text = fragmentShaderAbstractPattern2Proc.toGLSL(version = static versionStr)
    uniforms = fragmentShaderAbstractPattern2Proc.fetchUniforms()

  initialize(
    size = (width: 500, height: 500),
    title = "Abstract Pattern #2",
    version,
    fragmentShader = (text: text, uniforms: uniforms)
  )
  .render()


when isMainModule:
  quit(play())
