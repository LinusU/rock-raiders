
class RTSUnit extends RTS.Object
  setPosFromPath: (path) ->
    moveObj = (obj) ->
      obj.opts.x = path.x / 10
      obj.opts.y = path.y / 10
      obj.opts.heading = path.heading
      obj.mesh.position.x = path.x
      obj.mesh.position.y = path.y
      obj.mesh.rotation.z = path.heading

    moveObj @

    if @carryingObject
      moveObj @carryingObject

  walkTo: (tx, ty, cb) ->

    path = @map.getWalkPath Math.round(@opts.x * 10), Math.round(@opts.y * 10), tx, ty
    return false if path is null

    path.animate @, =>
      @busy = false
      if cb then do cb

    @busy = true
    return true

window.RTS.Unit = RTSUnit
