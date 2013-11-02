
geometry = new THREE.CubeGeometry(1, 2, 8)
material = new THREE.MeshLambertMaterial({ map: new THREE.ImageUtils.loadTexture 'LegoRR0/Mini-Figures/Pilot/Pback.bmp' })

GAudio.registerEffect 'pilot-dig', 'LegoRR0/Sounds/Minifigure/dig.wav'
GAudio.registerEffect 'pilot-drill', 'LegoRR0/Sounds/Minifigure/Pdrill.wav'
GAudio.registerEffect 'pilot-drop-ore', 'LegoRR0/Sounds/Minifigure/Rockdrop.wav'
GAudio.registerEffect 'pilot-drop-crystal', 'LegoRR0/Sounds/Minifigure/Crystaldrop.wav'

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
      if @idle-- is 0
        @idle = Math.round(Math.random() * 10)
        @work = @map.game.interface.findWork @
    if @work
      @idle = Math.round(Math.random() * 10)
      if (@work.x is @work.y is null) or @opts.x * 10 is @work.x and @opts.y * 10 is @work.y
        @executeWork cb
      else
        @walkTo @work.x, @work.y, cb
    else
      cb()
  executeWork: (cb) ->
    done = =>
      w2 = @work.getFollowUp()
      @busy = false
      @work = null
      if w2 then @demandWork w2
      cb()
    switch @work.action
      when 'drill-wall'
        @busy = true
        snd = GAudio.playEffect 'pilot-drill', true
        setTimeout =>
          snd.stop()
          @work.block.collapse()
          done()
        , 2000
      when 'clear-rubble'
        @busy = true
        snd = GAudio.playEffect 'pilot-dig', true
        setTimeout (=>
          snd.stop()
          @work.block.decreaseRubble()
          done()
        ), 1000
      when 'pickup-object'
        @busy = true
        setTimeout (=>
          @pickupObject @work.obj
          done()
        ), 320
      when 'drop-object'
        @busy = true
        if @work.obj.name() is 'Ore' then GAudio.playEffect 'pilot-drop-ore'
        if @work.obj.name() is 'Crystal' then GAudio.playEffect 'pilot-drop-crystal'
        setTimeout (=>
          @dropObject()
          done()
        ), 160
      when 'store-object'
        @busy = true
        if @work.obj.name() is 'Ore' then GAudio.playEffect 'pilot-drop-ore'
        if @work.obj.name() is 'Crystal' then GAudio.playEffect 'pilot-drop-crystal'
        setTimeout (=>
          assert @carryingObject is @work.obj
          @dropObject()
          @work.obj.destroy()
          if @work.obj.name() is 'Ore' then @map.game.interface.ore++
          if @work.obj.name() is 'Crystal' then @map.game.interface.crystal++
          done()
        ), 160
      when 'deposit-resource'
        @busy = true
        obj = @carryingObject
        if obj.name() is 'Ore' then GAudio.playEffect 'pilot-drop-ore'
        if obj.name() is 'Crystal' then GAudio.playEffect 'pilot-drop-crystal'
        setTimeout (=>
          @dropObject()
          obj.belongsToBuilding = true
          @work.block.notifyResource obj
          done()
        ), 160
      when 'withdraw-resource'
        @busy = true
        setTimeout (=>
          obj = switch @work.type
            when 'ore' then new RR.Ore @map, { x: @opts.x, y: @opts.y }
            when 'crystal' then new RR.Crystal @map, { x: @opts.x, y: @opts.y }
            else NotImplemented()
          @pickupObject obj
          done()
        ), 320
      when 'fetch-dynamite'
        @busy = true
        setTimeout (=>
          obj = new RR.Dynamite @map, { x: @opts.x, y: @opts.y }
          @pickupObject obj
          done()
        ), 320
      when 'blast-wall'
        @busy = true
        setTimeout (=>
          assert @carryingObject.name() is 'Dynamite'
          @carryingObject.lightFuse @work.block
          @dropObject()
          done()
        ), 160
  click: ->
    btns = []
    if @carryingObject then btns.push 'drop-object'
    btns.push 'delete'
    @map.game.selected.pilot = @
    @map.game.interface.setButtons btns, @
  canDoWork: (w) ->
    switch w.action
      when 'drill-wall', 'clear-rubble', 'pickup-object', 'fetch-dynamite'
        (@carryingObject is null) and (@canWalkTo w.x, w.y)
      when 'blast-wall'
        (@carryingObject.name() is 'Dynamite') and (@canWalkTo w.x, w.y)
      when 'deposit-resource'
        @canWalkTo w.x, w.y
      when 'store-object'
        if w.building
          [tx, ty] = w.building.xyForEntrance()
          @canWalkTo tx, ty
        else
          ts = @findToolstation()
          if ts then w.setBuilding ts
          (ts isnt null)
      else false
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
