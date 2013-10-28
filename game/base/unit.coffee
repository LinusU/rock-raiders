
class RTSUnit extends RTS.Object
  walkTo: (tx, ty, cb) ->
    path = @map.getWalkPath Math.round(@opts.x * 10), Math.round(@opts.y * 10), tx, ty
    return false if path.length is 0
    @busy = true
    setTimeout (r = =>

      [@opts.x, @opts.y] = path.shift().map (e) -> e / 10
      @mesh.position.set @opts.x * 10, @opts.y * 10, 0

      if @carryingObject
        @carryingObject.opts.x = @opts.x
        @carryingObject.opts.y = @opts.y
        @carryingObject.mesh.position.set @opts.x * 10, @opts.y * 10, 4

      if path.length > 0
        setTimeout r, 1000/15
      else
        @busy = false
        if cb then cb()
    ), (1000/15) / 2
    return true


window.RTS.Unit = RTSUnit
