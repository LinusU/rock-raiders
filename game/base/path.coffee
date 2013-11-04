
class RTSPath
  constructor: (@map, @points) ->
    @pos = 0
    @spd = (8 / 1000)
    @max = (@points.length - 1)
    @heading = 0
    [@x, @y] = @points[0]
  animate: (unit, cb) ->
    anim = new RTS.Animation
    abort = ->
      anim.destroy()
      if cb then cb()
    anim.tick = (dt) =>
      @walk dt
      unit.setPosFromPath @
      if @isDone() then abort()
  isDone: ->
    (@pos >= @max)
  walk: (dt) ->

    @pos += dt * @spd

    if @isDone()
      @pos = @max
      point = @points[@max]
    else
      pd = @pos % 1
      pf = Math.ceil @pos
      xy0 = @points[pf - 1]
      xy1 = @points[pf]
      point = [
        xy0[0] + ((xy1[0] - xy0[0]) * pd)
        xy0[1] + ((xy1[1] - xy0[1]) * pd)
      ]

    dx = point[0] - @x
    dy = point[1] - @y

    @heading = Math.atan2(dy, dx)
    [@x, @y] = point

window.RTS.Path = RTSPath
