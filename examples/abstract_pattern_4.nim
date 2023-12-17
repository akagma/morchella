import morchella
import morchella/math


proc random(v: float32): float32 =
  return fract(sin(v + 0.3423) * 100000.0)


proc fragmentShaderProc(
  gl_FragCoord: Vec4,
  resolution: Uniform[Vec2],
  time: Uniform[float32],
  gl_FragColor: var Vec4
) =
  var
    uv = (gl_FragCoord.xy * 2.0 - resolution.xy) / min(resolution.x, resolution.y)
    min1 = 100.0
    min2 = 200.0
  for i in 0..<40:
    var
      j = i.float32()
      p = vec2(random(j), random(j + 1000.0))
      r = random(j + 2000.0) * 0.05 + 0.05
      a = time * 0.02 + random(j + 3000.0) * 2.0 * PI
    p += vec2(r * cos(a), r * sin(a))
    var d = distance(p, uv)
    if min1 > d:
      min2 = min1
      min1 = d
    elif min2 > d:
      min2 = d

  var col = smoothstep(0.0, 0.004, min2 - min1)
  var color = vec3(col, col, col) 
  gl_FragColor = vec4(color, 1.0)


proc play(): int =
  const
    version = (major: 4, minor: 5)
    versionStr = $version.major & $version.minor & "0"
  
  let 
    fragmentShaderText = fragmentShaderProc.toGLSL(version = static versionStr)
    fragmentShaderUniforms = fragmentShaderProc.fetchUniforms()
  
  initialize(
    size = (width: 500, height: 500),
    title = "Abstract Pattern #4",
    version,
    fragmentShader = (text: fragmentShaderText, uniforms: fragmentShaderUniforms)
  )
  .render()


when isMainModule:
  quit(play())
