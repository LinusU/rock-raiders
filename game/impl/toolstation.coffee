
geometry = new THREE.CubeGeometry(8, 8, 1)
material = new THREE.MeshLambertMaterial({ color: 0x00aa00 })

class RRToolstation extends RTS.Building
  @all: []
  geometry: -> geometry
  material: -> material
  constructor: ->
    super

    RRToolstation.all.push @

    setTimeout (=> @mainLoop()), 100
  mainLoop: ->
    if @busy or @block.opts.hidden
      setTimeout (=> @mainLoop()), 1000
    else if @map.game.interface.mfQueue > 0
      @busy = true
      @map.game.interface.mfQueue--
      [tx, ty] = @xyForEntrance()
      obj = new RR.Pilot @map, { x: @opts.x, y: @opts.y, heading: @opts.heading }
      obj.walkTo tx, ty
      setTimeout (=> @busy = false; @work = null; @mainLoop()), 1000
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
