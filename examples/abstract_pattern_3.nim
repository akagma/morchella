import morchella
import morchella/math


proc fragmentShaderAbstractPattern3Proc(
  gl_FragCoord: Vec4,
  resolution: Uniform[Vec2],
  time: Uniform[float32],
  pixelColor: var Vec4
) =
  var
    uv = (gl_FragCoord.xy * 2.0 - resolution.xy) / min(resolution.x, resolution.y)
    noise = hashOld12(uv * time)
    col =
      1.0 -
      clamp(floor(length(uv) + 0.5), 0.0, 1.0) *
      clamp(floor(length(uv + 1.0) + 0.5), 0.0, 1.0) *
      clamp(floor(length(uv - 1.0) + 0.5), 0.0, 1.0) *
      clamp(floor(length(uv + vec2(1.0, -1.0)) + 0.5), 0.0, 1.0) *
      clamp(floor(length(uv + vec2(-1.0, 1.0)) + 0.5), 0.0, 1.0) *
      noise
  var color = vec3(col, col, col)
  pixelColor = vec4(color, 1.0)


proc play(): int =
  const
    version = (major: 4, minor: 5)
    versionStr = $version.major & $version.minor & "0"

  let
    text = fragmentShaderAbstractPattern3Proc.toGLSL(version = static versionStr)
    uniforms = fragmentShaderAbstractPattern3Proc.fetchUniforms()

  initialize(
    size = (width: 500, height: 500),
    title = "Abstract Pattern #3",
    version,
    fragmentShader = (text: text, uniforms: uniforms)
  )
  .render()


when isMainModule:
  quit(play())
