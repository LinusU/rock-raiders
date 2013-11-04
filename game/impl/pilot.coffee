
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
        @pickupObject @work.obj, -> done()
      when 'drop-object'
        @busy = true
        assert @carryingObject is @work.obj
        @dropObject -> done()
      when 'store-object'
        @busy = true
        assert @carryingObject is @work.obj
        @dropObject (obj) =>
          obj.destroy()
          if obj.name() is 'Ore' then @map.game.interface.ore++
          if obj.name() is 'Crystal' then @map.game.interface.crystal++
          done()
      when 'deposit-resource'
        @busy = true
        @dropObject (obj) =>
          obj.belongsToBuilding = true
          @work.block.notifyResource obj
          done()
      when 'withdraw-resource'
        @busy = true
        obj = switch @work.type
          when 'ore' then new RR.Ore @map, { x: @opts.x, y: @opts.y }
          when 'crystal' then new RR.Crystal @map, { x: @opts.x, y: @opts.y }
          else NotImplemented()
        @pickupObject obj, -> done()
      when 'fetch-dynamite'
        @busy = true
        obj = new RR.Dynamite @map, { x: @opts.x, y: @opts.y }
        @pickupObject obj, -> done()
      when 'blast-wall'
        assert @carryingObject.name() is 'Dynamite'
        @busy = true
        @dropObject (obj) =>
          obj.lightFuse @work.block
          done()
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
  pickupObject: (obj, cb) ->
    assert @carryingObject is null
    pos = 0
    ani = new RTS.Animation
    ani.tick = (dt) =>
      pos = Math.min 320, pos + dt
      obj.mesh.position.z = (pos / 320) * 4
      if pos is 320 then done()
    done = =>
      @carryingObject = obj
      obj.isPickedUpBy = @
      ani.destroy()
      cb()
  dropObject: (cb) ->
    assert @carryingObject
    obj = @carryingObject
    pos = 0
    ani = new RTS.Animation
    ani.tick = (dt) ->
      pos = Math.min 160, pos + dt
      obj.mesh.position.z = 4 - (pos / 160 * 4)
      if pos is 160 then done()
    done = =>
      if obj.name() is 'Ore' then GAudio.playEffect 'pilot-drop-ore'
      if obj.name() is 'Crystal' then GAudio.playEffect 'pilot-drop-crystal'
      delete obj.isPickedUpBy
      @carryingObject = null
      ani.destroy()
      cb obj
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
