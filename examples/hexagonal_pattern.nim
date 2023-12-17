import morchella
import morchella/math


proc hexDist(p: var Vec2): float32 =
  p = abs(p)
  var d = dot(p, normalize(vec2(1.0, 1.73)))
  return max(p.x, d)


proc hexCoords(uv: Vec2): Vec4 =
  var
    r: Vec2 = normalize(vec2(1.0, 1.73))
    h: Vec2 = r * 0.5
    a: Vec2 = (uv mod r) - h
    b: Vec2 = ((uv - h) mod r) - h

    gv: Vec2 =
      if length(a) < length(b): a
      else: b

    x = atan(gv.x, gv.y)
    y = 0.5 - hexDist(gv)
    id = uv - gv

  return vec4(vec2(x, y), id)


proc hexagonalPattern(
  gl_FragCoord: Vec4,
  resolution: Uniform[Vec2],
  time: Uniform[float32],
  pixelColor: var Vec4
) =
  var
    uv = (gl_FragCoord.xy * vec2(2.0) - resolution.xy) / min(resolution.x, resolution.y)
    col = vec3(0.0)

    hc = hexCoords(uv)
    r = (1 + cos(length(hc.zw) - time - 0.43)) * 0.3 + 0.3
    g = (1 + cos(length(hc.zw) - time - 0.27)) * 0.3 + 0.3
    b = (1 + cos(length(hc.zw) - time - 0.1)) * 0.3 + 0.3
    c = smoothstep(0.0, 0.02, hc.y)

  col = c * vec3(r, g, b)
  pixelColor = vec4(col, 1.0)


proc play(): int =
  const
    version = (major: 4, minor: 5)
    versionStr = $version.major & $version.minor & "0"

  let
    text = hexagonalPattern.toGLSL(version = static versionStr)
    uniforms = hexagonalPattern.fetchUniforms()

  initialize(
    size = (width: 500, height: 500),
    title = "Hexagonal Pattern",
    version = version,
    fragmentShader = (text: text, uniforms: uniforms)
  )
  .render()


when isMainModule:
  quit(play())
