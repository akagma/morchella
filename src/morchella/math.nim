import vmath


# Nim does not have atan proc (but math.arctan has),
# so we have to define it for using in fragment shader procs.
proc atan*(a, b: float32): float32 {.importc: "atanf", header: "<math.h>".}


proc asin*(a: float32): float32 {.importc: "asinf", header: "<math.h>".}


proc acos*(a: float32): float32 {.importc: "acosf", header: "<math.h>".}


# Nim has math.log, but it has two arguments x: float32, base: T.
# It is difference from GLSL's log function.
# So we have to define it for using in fragment shader procs.
proc log*(x: float32): float32 {.importc: "logf", header: "<math.h>".}


proc cross*(a, b: Vec3): Vec3 =
  return vec3(
    a.y * b.z - b.y * a.z,
    a.z * b.x - b.z * a.x,
    a.x * b.y - b.x * a.y
  )


proc distance*(a, b: float32): float32 =
  return abs(a - b)


proc distance*(a, b: Vec2): float32 =
  return abs(length(a) - length(b))


proc distance*(a, b: Vec3): float32 =
  return abs(length(a) - length(b))


proc smin*(d1, d2, k: float32): float32 =
  var h = clamp(0.5 + 0.5 * (d2 - d1) / k, 0.0, 1.0)
  return mix(d2, d1, h) - k * h * (1.0 - h)


proc `mod`*(a, b: float32): float32 = 
  return a - b * floor(a / b)


proc `mod`*(a, b: Vec2): Vec2 =
  return vec2(a.x mod b.x, a.y mod b.y)


proc `mod`*(a, b: Vec3): Vec3 =
  return vec3(a.x mod b.x, a.y mod b.y, a.z mod b.z)


proc smoothstep*(e1, e2, x: float32): float32 =
  let t = clamp((x - e1) / (e2 - e1), 0, 1)
  return t * t * (3 - 2 * t)


proc fract*(x: float32): float32 =
  return x - floor(x)


proc fract2*(x: Vec2): Vec2 =
  return x - floor(x)


proc fract3*(x: Vec3): Vec3 =
  return x - floor(x)


proc rotate2D*(vec: Vec2, angle: float32): Vec2 =
  vec2(vec.x * cos(angle) - vec.y * sin(angle), vec.x * sin(angle) + vec.y * cos(angle))


proc rgb2hsv*(rgb: Vec3): Vec3 =
  let
    tau: float32 = acos(-1.0) * 2.0

    ma = max(max(rgb.x, rgb.y), rgb.z)
    mi = min(min(rgb.x, rgb.y), rgb.z)
    delta = ma - mi
    s =
      if ma > 0.0: delta / ma
      else: 0.0
    v = ma

  var
    h: float32 = 0.0

  if s > 0.0:
    if ma == rgb.x:
      h = (rgb.y - rgb.z) / delta
    elif ma == rgb.y:
      h = (rgb.z - rgb.x) / delta + tau / 3.0
    else:
      h = (rgb.x - rgb.y) / delta + 2.0 * tau / 3.0

  return vec3(h mod tau, s, v)


proc hsv2rgb*(c: Vec3): Vec3 =
  var
    k: Vec4 = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0)
    p: Vec3 = abs(fract3(c.xxx + k.xyz) * vec3(6.0) - k.www)
    val: Vec3 = p - k.xxx
    clampVal: Vec3 = vec3(
      clamp(val.x, (0.0).float32(), (1.0).float32()),
      clamp(val.y, (0.0).float32(), (1.0).float32()),
      clamp(val.z, (0.0).float32(), (1.0).float32())
    )
  return vec3(c.z) * mix(k.xxx, clampVal, c.y)


proc hash12*(p: Vec2): float32 =
  var p3: Vec3 = fract3(vec3(p.xyx) * vec3(0.1031))
  p3 += vec3(dot(p3, p3.yzx + 33.33))
  return fract((p3.x + p3.y) * p3.z)


proc hashOld12*(p: Vec2): float32 =
  return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453)
