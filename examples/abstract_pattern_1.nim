import morchella
import morchella/math


proc fragmentShaderAbstractPattern1Proc(
  gl_FragCoord: Vec4,
  resolution: Uniform[Vec2],
  time: Uniform[float32],
  pixelColor: var Vec4
) =
  var
    uv = (gl_FragCoord.xy * 2.0 - resolution.xy) / min(resolution.x, resolution.y)
    a = vec2(sin(time), cos(time)) + uv
    b = vec2(cos(time), sin(time)) + uv
    c = dot(vec2(hashOld12(a - vec2(hash12(b)))), uv)
    division = 64.0
    d = length(vec3(division) * vec3(uv, 0.5) - fract3(vec3(division) * vec3(uv, 0.5)))
    color = vec3(
      smin(sin(c), cos(d), sin(time)) * sin(c + d),
      smin(sin(c), cos(d), sin(time)) * sin(smin(c, d, time) + 5.0 * d),
      smin(sin(c), cos(d), sin(time)) * sin(c + d + time + 10.0 * hash12(vec2(d)))
    )
  pixelColor = vec4(color, 1.0)


proc play(): int =
  const
    version = (major: 4, minor: 5)
    versionStr = $version.major & $version.minor & "0"
  
  let
    text = fragmentShaderAbstractPattern1Proc.toGLSL(version = static versionStr)
    uniforms = fragmentShaderAbstractPattern1Proc.fetchUniforms()

  initialize(
    size = (width: 500, height: 500),
    title = "Abstract Pattern #1",
    version,
    fragmentShader = (text: text, uniforms: uniforms)
  )
  .render()


when isMainModule:
  quit(play())
