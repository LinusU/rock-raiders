
class RTSUnit extends RTS.Object
  @walking: []
  walkTo: (tx, ty, cb) ->

    path = @map.getWalkPath Math.round(@opts.x * 10), Math.round(@opts.y * 10), tx, ty
    return false if path is null

    moveObj = (obj) ->
      obj.opts.x = path.x / 10
      obj.opts.y = path.y / 10
      obj.opts.heading = path.heading
      obj.mesh.position.x = path.x
      obj.mesh.position.y = path.y
      obj.mesh.rotation.z = path.heading

    tick = (dt) =>

      path.walk dt
      moveObj @

      if @carryingObject
        moveObj @carryingObject

      if path.isDone()
        @busy = false
        RTSUnit.walking.remove tick
        if cb then do cb

    @busy = true
    RTSUnit.walking.push tick
    return true

window.RTS.Unit = RTSUnit
