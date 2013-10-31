
class RTSObject
  constructor: (@map, @opts) ->
    @predicted = {}
    @_refreshMesh()
  destroy: ->
    @map.game.scene.remove @mesh
  refreshMesh: ->
    @_noMesh = false
    @_refreshMesh()
  _refreshMesh: ->

    if @mesh then @map.game.scene.remove @mesh
    if @_noMesh then return

    @mesh = new THREE.Mesh @geometry(), @material()
    @mesh.rotation.z = (Math.PI / 180) * (@opts.heading || 0)

    if @ instanceof RTS.Block
      @mesh.position.set @opts.x * 10 + 5, @opts.y * 10 + 5, 0
    else
      @mesh.position.set @opts.x * 10, @opts.y * 10, 0

    @mesh._on_click = => @click.apply @, arguments
    @map.game.scene.add @mesh

  canWalkTo: (tx, ty) ->
    @map.getWalkPath(Math.round(@opts.x * 10), Math.round(@opts.y * 10), tx, ty).length > 0
  deltaXY: ->
    switch Math.round(@opts.heading)
      when 0 then [0, -1]
      when 90 then [-1, 0]
      when 180 then [0, 1]
      when 270 then [1, 0]
      else console.log(@, @opts.heading); assert false
  findToolstation: ->
    for ts in RR.Toolstation.all
      if ts.block.hidden then continue
      [tx, ty] = ts.xyForEntrance()
      if @canWalkTo(tx, ty) then return ts
    return null
  _on_click: (point) ->
    if @isPickedUpBy
      LOG @opts.type, '(forward click)'
      @isPickedUpBy._on_click point
    else
      LOG @opts.type, 'click'
      @click point

window.RTS.Object = RTSObject
