
geometry = new THREE.CubeGeometry(8, 8, 1)
material = new THREE.MeshLambertMaterial({ map: new THREE.ImageUtils.loadTexture 'LegoRR0/Buildings/ToolStation/MAINtopOLD.bmp' })

GAudio.registerEffect 'teleport', 'LegoRR0/Sounds/Teleport.wav'

class RRToolstation extends RTS.Building
  @all: []
  geometry: -> geometry
  material: -> material
  constructor: ->
    super

    RRToolstation.all.push @
    setTimeout (=> @mainLoop()), 1000

  _refreshMesh: ->
    super

    @mesh.rotation.z = -Math.PI / 2

  mainLoop: ->
    if @busy or @block.opts.hidden
      setTimeout (=> @mainLoop()), 1000
    else if @map.game.interface.mfQueue > 0
      @busy = true
      @map.game.interface.mfQueue--
      GAudio.playEffect 'teleport'
      [tx, ty] = @xyForEntrance()
      obj = new RR.Pilot @map, { x: @opts.x, y: @opts.y, heading: @opts.heading }
      obj.walkTo tx, ty
      obj.idle = 50
      setTimeout (=> @busy = false; @mainLoop()), 2500
    else
      setTimeout (=> @mainLoop()), 330
  destroy: ->
    RRToolstation.all.remove @
    super
  click: ->
    p = @map.game.selected.pilot
    if p and p.carryingObject
      p.demandWork new RTS.Work { action: 'store-object', building: @, obj: p.carryingObject }
      @map.game.selected.clear()
      @map.game.interface.mainMenu()



window.RR.Toolstation = RRToolstation
