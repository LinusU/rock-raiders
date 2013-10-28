
VZ = new THREE.Vector3(0, 0, 1)

class RTSObject
  constructor: (@map, @opts) ->
    @mesh = new THREE.Mesh @geometry(), @material()
    @mesh.rotateOnAxis VZ, (Math.PI / 180) * (@opts.heading || 0)
    @mesh.position.set @opts.x * 10, @opts.y * 10, 0
    @mesh._on_click = => @click.apply @, arguments
    @map.game.scene.add @mesh
  destroy: ->
    @map.game.scene.remove @mesh
  canWalkTo: (tx, ty) ->
    @map.getWalkPath(Math.round(@opts.x * 10), Math.round(@opts.y * 10), tx, ty).length > 0
  deltaXY: ->
    switch @opts.heading
      when 0 then [0, -1]
      when 90 then [-1, 0]
      when 180 then [0, 1]
      when 270 then [1, 0]
      else console.log(@, @opts.heading); assert false
  _on_click: (point) ->
    if @isPickedUpBy
      LOG @opts.type, '(forward click)'
      @isPickedUpBy._on_click point
    else
      LOG @opts.type, 'click'
      @click point

window.RTS.Object = RTSObject
