import morchella
import morchella/math


proc fragmentShaderFlowerPattern(
  gl_FragCoord: Vec4,
  resolution: Uniform[Vec2],
  time: Uniform[float32],
  pixelColor: var Vec4
) =
  let
    amplitude = vec3(1.0, 10.0, 20.0)
    phase = vec3(10.0, 30.0, 50.0)
    frequency = vec3(10.0, 30.0, 50.0)
    p: Vec2 = (gl_FragCoord.xy * vec2(2.0, 2.0) - resolution.xy) / min(resolution.x, resolution.y)
    r = 0.01 / abs(
      0.5 +
      amplitude.x *
        sin(
          (atan(p.y, p.x) + (time + phase.x) * 0.1) *
          frequency.x
        ) *
        0.01 -
      length(p)
    )
    g = 0.01 / abs(
      0.5 +
      amplitude.y *
        sin(
          (atan(p.y, p.x) + (time + phase.y) * 0.1) *
          frequency.y
        ) *
        0.01 -
      length(p)
    )
    b = 0.01 / abs(
      0.5 +
      amplitude.z *
        sin(
          (atan(p.y, p.x) + (time + phase.z) * 0.1) *
          frequency.z
        ) *
        0.01 -
      length(p)
    )

  pixelColor = vec4(r, g, b, 1.0)


proc play(): int =
  const
    version = (major: 4, minor: 5)
    versionStr = $version.major & $version.minor & "0"

  let
    text = fragmentShaderFlowerPattern.toGLSL(version = static versionStr)
    uniforms = fragmentShaderFlowerPattern.fetchUniforms()

  initialize(
    size = (width: 500, height: 500),
    title = "Flower Pattern",
    version,
    fragmentShader = (text: text, uniforms: uniforms)
  )
  .render()


when isMainModule:
  quit(play())
