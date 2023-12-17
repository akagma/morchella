# This implementation was heavily influenced by
# https://github.com/pedrotrschneider/shader-fractals/blob/main/3D/Mandelbulb.glsl

import morchella
import morchella/math


proc rot(angle: float32, v: Vec2): Vec2 =
  let
    s: float32 = sin(angle)
    c: float32 = cos(angle)
  return vec2(v.x * c + v.y * s, -v.x * s + v.y * c)


proc getRayDirection(uv: Vec2, p: Vec3, l: Vec3, z: float32): Vec3 =
  var
    f: Vec3 = normalize(l - p)
    r: Vec3 = normalize(cross(vec3(0.0, 1.0, 0.0), f))
    u: Vec3 = cross(f, r)
    c: Vec3 = p + f * vec3(z)
    i: Vec3 = c + vec3(uv.x) * r + vec3(uv.y) * u
    d: Vec3 = normalize(i - p)
  return d


proc hsv2rgb(c: Vec3): Vec3 =
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


proc map(value: float32, min1: float32, max1: float32, min2: float32, max2: float32): float32 =
  return min2 + (value - min1) * (max2 - min2) / (max1 - min1)


proc mandelbulb(position: Vec3, time: float32): float32 =
  var
    z: Vec3 = position
    dr: float32 = 1.0
    r: float32 = 0.0
    iterations: int32 = 0

  let
    power: float32 = 8.0 + (5.0 * map(sin(time * PI / 10.0 + PI), -1.0, 1.0, 0.0, 1.0))

  for i in 0..<10:
    iterations = i.int32()
    r = length(z)

    if r > 2.0:
      break

    var
      theta: float32 = acos(z.z / r)
      phi: float32 = atan(z.y, z.x)

    let
      zr: float32 = pow(r, power)

    dr = pow(r, power - 1.0) * power * dr + 1.0
    theta = theta * power
    phi = phi * power

    z = vec3(zr) * vec3(sin(theta) * cos(phi), sin(phi) * sin(theta), cos(theta))
    z += position

  let dst: float32 = 0.5 * log(r) * r / dr
  return dst


proc distanceEstimator(p: Vec3, time: float32): float32 =
  var pp: Vec3 = p
  let temp: Vec2 = rot((-0.3 * PI).float32(), pp.yz)
  pp = vec3(pp.x, temp.x, temp.y)
  let mandelbulbVal: float32 = mandelbulb(pp, time)
  return mandelbulbVal


const
  maximumRaySteps: int32 = 250
  maximumDistance: float32 = 200.0
  minimumDistance: float32 = 0.0001


proc rayMarcher(ro: Vec3, rd: Vec3, time: float32): Vec4 =
  var
    steps: int32 = 0
    totalDistance: float32 = 0.0f
    minDistToScene: float32 = 100.0f
    minDistToScenePos: Vec3 = ro
    minDistToOrigin: float32 = 100.0f
    minDistToOriginPos: Vec3 = ro
    col: Vec3 = vec3(0.0, 0.0, 0.0)
    curPos: Vec3 = ro
    hit: bool = false

  for s in 0..<maximumRaySteps:
    steps = s.int32()
    curPos = ro + rd * vec3(totalDistance)

    let distance: float32 = distanceEstimator(curPos, time)
    if minDistToScene > distance:
      minDistToScene = distance
      minDistToScenePos = curPos

    if minDistToOrigin > length(curPos):
      minDistToOrigin = length(curPos)
      minDistToOriginPos = curPos

    totalDistance += distance
    if distance < minimumDistance:
      hit = true
      break
    elif distance > maximumDistance:
      break

  if hit:
    col = vec3(0.8 + (length(curPos) / 0.5), 1.0, 0.8)
    col = hsv2rgb(col)
  else:
    col = vec3(0.8 + (length(minDistToScenePos) / 0.5), 1.0, 0.8)
    col = hsv2rgb(col)
    col = col * vec3(1.0 / (minDistToScene * minDistToScene))
    col = col / vec3(map(sin(time * 3.0), -1.0, 1.0, 3000.0, 50000.0))

  col = col / vec3(steps.float32() * 0.08)
  col = col / vec3(pow(abs(length(ro) - length(minDistToScenePos)), 2.0))
  col = col * vec3(3.0)

  return vec4(col, 1.0)


proc fragmentShaderProc(
  gl_FragCoord: Vec4,
  resolution: Uniform[Vec2],
  time: Uniform[float32],
  pixelColor: var Vec4
) =
  let
    uv = 
      vec2(1.5) * (gl_FragCoord.xy - vec2(0.5) * resolution.xy) / min(resolution.x, resolution.y)
    ro: Vec3 = vec3(0.0, 0.0, -2.0)
    rd: Vec3 = getRayDirection(
      uv,
      ro,
      vec3(0.0, 0.0, 1.0),
      (1.0).float32()
    )
    
  pixelColor = rayMarcher(ro, rd, time)


proc play(): int =
  const
    version = (major: 4, minor: 5)
    versionStr = $version.major & $version.minor & "0"

  let
    text = fragmentShaderProc.toGLSL(version = static versionStr)
    uniforms = fragmentShaderProc.fetchUniforms()

  initialize(
    size = (width: 500, height: 500),
    title = "Mandelbulb",
    version,
    fragmentShader = (text: text, uniforms: uniforms)
  )
  .render()


when isMainModule:
  quit(play())
