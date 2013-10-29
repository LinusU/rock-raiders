
geometry = new THREE.CubeGeometry(2, 1, 8)
material = new THREE.MeshLambertMaterial({ color: 0xaa0000 })

class RRPilot extends RTS.Unit
  geometry: -> geometry
  material: -> material
  constructor: ->
    super
    @idle = 0
    @work = null
    @busy = false
    @carryingObject = null
    setTimeout (=> @mainLoop()), 100
  mainLoop: ->
    # LOL, who the fuck has a separate main loop for each unit
    cb = => setTimeout (=> @mainLoop()), 100
    if @busy
      cb()
      return
    if @work is null
      w = @map.game.interface.getWork()
      if w isnt null
        if @canDoWork w
          @work = w
        else
          @map.game.interface.addWork w
    if @work is null
      if @idle++ > 30 + (Math.random() * 30)
        @idle = 0
        @work = @map.game.interface.findWork @
    if @work
      @idle = 0
      if (@work.x is @work.y is null) or @opts.x * 10 is @work.x and @opts.y * 10 is @work.y
        @executeWork cb
      else
        @walkTo @work.x, @work.y, cb
    else
      cb()
  executeWork: (cb) ->
    switch @work.action
      when 'drill-wall'
        @busy = true
        setTimeout =>
          @work.block.collapse()
          @busy = false
          @work = null
          cb()
        , 2000
      when 'clear-rubble'
        @busy = true
        setTimeout (r = =>
          @work.block.decreaseRubble()
          @busy = false
          @work = null
          cb()
        ), 1000
      when 'pickup-object', 'collect-resource'
        @busy = true
        setTimeout (r = =>
          w = @work
          @pickupObject w.obj
          @busy = false
          @work = null
          if w.action is 'collect-resource'
            @demandWork w.nextWork
          else
            @storeCurrentObject()
          cb()
        ), 320
      when 'drop-object'
        @busy = true
        setTimeout (r = =>
          @dropObject()
          @busy = false
          @work = null
          cb()
        ), 160
      when 'store-object'
        @busy = true
        setTimeout (r = =>
          obj = @carryingObject
          @dropObject()
          obj.destroy()
          if obj.name() is 'Ore' then @map.game.interface.ore++
          if obj.name() is 'Crystal' then @map.game.interface.crystal++
          @busy = false
          @work = null
          cb()
        ), 160
  click: ->
    btns = []
    if @carryingObject then btns.push 'drop-object'
    btns.push 'delete'
    @map.game.selected.pilot = @
    @map.game.interface.setButtons btns, @
  canDoWork: (w) ->
    switch w.action
      when 'drill-wall', 'clear-rubble', 'collect-resource', 'pickup-object'
        (@carryingObject is null) and (@canWalkTo w.x, w.y)
      when 'store-object'
        if w.building
          [tx, ty] = w.building.xyForEntrance()
          @canWalkTo tx, ty
        else
          ts = @findToolstation()
          if ts then w.setBuilding ts
          (ts isnt null)
      else false
  findToolstation: ->
    for ts in RR.Toolstation.all
      if ts.block.hidden then continue
      [tx, ty] = ts.xyForEntrance()
      if @canWalkTo(tx, ty) then return ts
    return null
  pickupObject: (obj) ->
    assert @carryingObject is null
    @carryingObject = obj
    obj.isPickedUpBy = @
    obj.mesh.position.set obj.opts.x * 10, obj.opts.y * 10, 4
  dropObject: ->
    assert @carryingObject
    obj = @carryingObject
    delete obj.isPickedUpBy
    obj.mesh.position.set obj.opts.x * 10, obj.opts.y * 10, 0
    @carryingObject = null
  storeCurrentObject: ->
    assert @carryingObject
    ts = @findToolstation()
    if ts isnt null
      @demandWork new RTS.Work { action: 'store-object', building: ts, obj: @carryingObject }
  demandWork: (work) ->
    assert work
    if @work is null and not @busy
      @work = work
    else
      LOG 'FIXME', 'abort current work, put it back in the pool and start this work'

window.RR.Pilot = RRPilot
