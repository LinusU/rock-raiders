
VZ = new THREE.Vector3(0, 0, 1)

class RTSBlock
  @allWithRubble: []
  @materials: {}
  constructor: (@map, @opts) ->
    @predicted = {}
    @resources = { ore: 0, crystal: 0 }
  click: (point) ->
    if @opts.hidden
      return
    else if @map.game.selected.pilot
      if @opts.type is 'wall' and @opts.strength < 4
        @map.game.selected.pilot.demandWork new RTS.Work { action: 'drill-wall', block: @ }
        @map.game.selected.clear()
        @map.game.interface.mainMenu()
      else if @opts.type is 'floor'
        if @opts.rubble
          @map.game.selected.pilot.demandWork new RTS.Work { action: 'clear-rubble', block: @ }
        else
          @map.game.selected.pilot.walkTo Math.round(point.x), Math.round(point.y)
        @map.game.selected.clear()
        @map.game.interface.mainMenu()
    else
      btns = [ 'main-menu' ]
      if @opts.type is 'floor'
        if (@opts.rubble || 0) > 0 then btns.push 'clear-rubble'
        if (@opts.rubble || 0) < 1 then btns.push 'build-path'
      if @opts.type is 'wall'
        if @opts.strength < 4 then btns.push 'drill-wall'
      @map.game.interface.setButtons btns, @
  getAdj: (num) =>
    adj = ''
    for i in num
      b = @map.getBlock @opts.x - 1 + (i % 3), @opts.y - 1 + Math.floor(i / 3)
      if b isnt null and b.opts.type in ['floor', 'lava', 'water']
        adj += 'F'
      else
        adj += 'W'
    adj
  updateOpts: ->

    if @partOfHiddenCavern
      @opts.hidden = true
      return

    @opts.hidden = do =>
      for i in [0, 1, 2, 3, 5, 6, 7, 8]
        b = @map.getBlock @opts.x - 1 + (i % 3), @opts.y - 1 + Math.floor(i / 3)
        if b isnt null and b.opts.type in ['floor', 'lava', 'water']
          return false
      return true

    if @opts.hidden then return

    walkable = (@opts.type is 'floor')
    [x, y] = [@opts.x * 10, @opts.y * 10]
    for i in [0..9]
      @map.grid.setWalkableAt x + i, y, walkable
      @map.grid.setWalkableAt x, y + i, walkable
      @map.grid.setWalkableAt x + i, y + 9, walkable
      @map.grid.setWalkableAt x + 9, y + i, walkable

    if @opts.type is 'wall'
      switch @getAdj [1, 3, 5, 7]
        when 'WWWF' then @opts.r = 2; @opts.wallType = 1;
        when 'WWFW' then @opts.r = 1; @opts.wallType = 1;
        when 'WFWW' then @opts.r = 3; @opts.wallType = 1;
        when 'FWWW' then @opts.r = 0; @opts.wallType = 1;

        when 'WWFF' then @opts.r = 1; @opts.wallType = 2;
        when 'WFWF' then @opts.r = 2; @opts.wallType = 2;
        when 'FFWW' then @opts.r = 3; @opts.wallType = 2;
        when 'FWFW' then @opts.r = 0; @opts.wallType = 2;

        when 'WWWW'
          switch @getAdj [0, 2, 6, 8]
            when 'WWWF' then @opts.r = 1; @opts.wallType = 3;
            when 'WWFW' then @opts.r = 2; @opts.wallType = 3;
            when 'WFWW' then @opts.r = 0; @opts.wallType = 3;
            when 'FWWW' then @opts.r = 3; @opts.wallType = 3;
            when 'FWWF' then @opts.r = 0; @opts.wallType = 4;
            when 'WFFW' then @opts.r = 1; @opts.wallType = 4;
            else
              # Just wait
        else
          @collapse()

  createMesh: ->

    @updateOpts()

    @mesh = new THREE.Mesh @getGeometry(), @getMaterial()
    @mesh.position.set @opts.x * 10 + 5, @opts.y * 10 + 5, 0
    @mesh.rotateOnAxis VZ, (Math.PI / 2) * (@opts.r || 0)
    @mesh._on_click = => @click.apply @, arguments
    @map.game.scene.add @mesh

  updateMesh: ->

    @map.game.scene.remove @mesh

    @mesh = new THREE.Mesh @getGeometry(), @getMaterial()
    @mesh.position.set @opts.x * 10 + 5, @opts.y * 10 + 5, 0
    @mesh.rotateOnAxis VZ, (Math.PI / 2) * (@opts.r || 0)
    @mesh._on_click = => @click.apply @, arguments
    @map.game.scene.add @mesh

  getMaterial: ->
    if @opts.hidden then return RTSBlock.materials[70]
    switch @opts.type
      when 'water' then RTSBlock.materials[45]
      when 'lava' then RTSBlock.materials[46]
      when 'floor'
        if @hasBuilding
          return RTSBlock.materials[76]
        switch @opts.rubble
          when 1 then RTSBlock.materials[13]
          when 2 then RTSBlock.materials[12]
          when 3 then RTSBlock.materials[11]
          when 4 then RTSBlock.materials[10]
          else RTSBlock.materials[0]
      when 'wall'
        switch @opts.wallType
          when 1 then RTSBlock.materials[ 1 + @opts.strength]
          when 2 then RTSBlock.materials[51 + @opts.strength]
          when 3 then RTSBlock.materials[31 + @opts.strength]
          when 4 then RTSBlock.materials[77]
          else assert false
      else NotImplemented()

  getGeometry: ->

    if @opts.hidden
      zs = [1, 1, 1, 1]

    else if @opts.type in ['floor', 'lava', 'water']
      zs = [0, 0, 0, 0]

    else if @opts.type is 'wall'
      switch @opts.wallType
        when 1 then zs = [0, 0, 1, 1]
        when 2 then zs = [0, 0, 1, 0]
        when 3 then zs = [1, 0, 1, 1]
        when 4 then zs = [0, 1, 1, 0]
        else console.log(@opts.wallType); assert false

    geo = new THREE.Geometry

    geo.vertices.push new THREE.Vector3 -5, -5, zs[0] * 10
    geo.vertices.push new THREE.Vector3  5, -5, zs[1] * 10
    geo.vertices.push new THREE.Vector3 -5,  5, zs[2] * 10
    geo.vertices.push new THREE.Vector3  5,  5, zs[3] * 10

    geo.faces.push new THREE.Face3 0, 1, 2
    geo.faces.push new THREE.Face3 1, 3, 2

    geo.faceVertexUvs[0].push [
      new THREE.Vector2 0, 0
      new THREE.Vector2 1, 0
      new THREE.Vector2 0, 1
    ]

    geo.faceVertexUvs[0].push [
      new THREE.Vector2 1, 0
      new THREE.Vector2 1, 1
      new THREE.Vector2 0, 1
    ]

    return geo

  collapse: (noRubble = false) ->
    @opts.type = 'floor'
    @opts.rubble = (if noRubble then 0 else 4)
    if @opts.rubble > 0 then RTSBlock.allWithRubble.push @
    rand = -> 0.2 + (Math.random() * 0.6)
    repeat @resources.ore, => new RR.Ore @map, { x: @opts.x + rand(), y: @opts.y + rand() }
    repeat @resources.crystal, => new RR.Crystal @map, { x: @opts.x + rand(), y: @opts.y + rand() }
    @updateOpts()
    if @mesh then @updateMesh()
    for i in [0, 1, 2, 3, 5, 6, 7, 8]
      b = @map.getBlock @opts.x - 1 + (i % 3), @opts.y - 1 + Math.floor(i / 3)
      if b isnt null and b.opts.type is 'wall'
        if b.partOfHiddenCavern
          delete b.partOfHiddenCavern
          b.opts.hidden = false
          b.collapse true
        else
          b.updateOpts()
          if b.mesh then b.updateMesh()
  decreaseRubble: ->
    if @opts.rubble
      @opts.rubble -= 1
      @updateOpts()
      @updateMesh()
      rand = -> 0.2 + (Math.random() * 0.6)
      new RR.Ore @map, { x: @opts.x + rand(), y: @opts.y + rand() }
      if @opts.rubble is 0 then RTSBlock.allWithRubble.remove @
  xyForDrillWall: ->
    adj = @getAdj [1, 3, 5, 7]
    if adj[0] is 'F'
      [dx, dy] = [0, -1]
      [px, py] = [5, 9]
    else if adj[1] is 'F'
      [dx, dy] = [-1, 0]
      [px, py] = [9, 5]
    else if adj[2] is 'F'
      [dx, dy] = [1, 0]
      [px, py] = [0, 5]
    else if adj[3] is 'F'
      [dx, dy] = [0, 1]
      [px, py] = [5, 0]
    target = @map.getBlock @opts.x + dx, @opts.y + dy
    return [target.opts.x * 10 + px, target.opts.y * 10 + py]

RTSBlock.materials[0] = new THREE.MeshLambertMaterial { map: new THREE.ImageUtils.loadTexture 'LegoRR0/World/WorldTextures/IceSplit/ICE00.BMP' }
RTSBlock.materials[1] = new THREE.MeshLambertMaterial { map: new THREE.ImageUtils.loadTexture 'LegoRR0/World/WorldTextures/IceSplit/ICE01.BMP' }
RTSBlock.materials[2] = new THREE.MeshLambertMaterial { map: new THREE.ImageUtils.loadTexture 'LegoRR0/World/WorldTextures/IceSplit/ICE02.BMP' }
RTSBlock.materials[3] = new THREE.MeshLambertMaterial { map: new THREE.ImageUtils.loadTexture 'LegoRR0/World/WorldTextures/IceSplit/ICE03.BMP' }
RTSBlock.materials[4] = new THREE.MeshLambertMaterial { map: new THREE.ImageUtils.loadTexture 'LegoRR0/World/WorldTextures/IceSplit/ICE04.BMP' }
RTSBlock.materials[5] = new THREE.MeshLambertMaterial { map: new THREE.ImageUtils.loadTexture 'LegoRR0/World/WorldTextures/IceSplit/ICE05.BMP' }

RTSBlock.materials[10] = new THREE.MeshLambertMaterial { map: new THREE.ImageUtils.loadTexture 'LegoRR0/World/WorldTextures/IceSplit/ICE10.BMP' }
RTSBlock.materials[11] = new THREE.MeshLambertMaterial { map: new THREE.ImageUtils.loadTexture 'LegoRR0/World/WorldTextures/IceSplit/ICE11.BMP' }
RTSBlock.materials[12] = new THREE.MeshLambertMaterial { map: new THREE.ImageUtils.loadTexture 'LegoRR0/World/WorldTextures/IceSplit/ICE12.BMP' }
RTSBlock.materials[13] = new THREE.MeshLambertMaterial { map: new THREE.ImageUtils.loadTexture 'LegoRR0/World/WorldTextures/IceSplit/ICE13.BMP' }

RTSBlock.materials[31] = new THREE.MeshLambertMaterial { map: new THREE.ImageUtils.loadTexture 'LegoRR0/World/WorldTextures/IceSplit/ICE31.BMP' }
RTSBlock.materials[32] = new THREE.MeshLambertMaterial { map: new THREE.ImageUtils.loadTexture 'LegoRR0/World/WorldTextures/IceSplit/ICE32.BMP' }
RTSBlock.materials[33] = new THREE.MeshLambertMaterial { map: new THREE.ImageUtils.loadTexture 'LegoRR0/World/WorldTextures/IceSplit/ICE33.BMP' }
RTSBlock.materials[34] = new THREE.MeshLambertMaterial { map: new THREE.ImageUtils.loadTexture 'LegoRR0/World/WorldTextures/IceSplit/ICE34.BMP' }
RTSBlock.materials[35] = new THREE.MeshLambertMaterial { map: new THREE.ImageUtils.loadTexture 'LegoRR0/World/WorldTextures/IceSplit/ICE35.BMP' }

RTSBlock.materials[45] = new THREE.MeshLambertMaterial { map: new THREE.ImageUtils.loadTexture 'LegoRR0/World/WorldTextures/IceSplit/ICE45.BMP' }
RTSBlock.materials[46] = new THREE.MeshLambertMaterial { map: new THREE.ImageUtils.loadTexture 'LegoRR0/World/WorldTextures/IceSplit/ICE46.BMP' }

RTSBlock.materials[51] = new THREE.MeshLambertMaterial { map: new THREE.ImageUtils.loadTexture 'LegoRR0/World/WorldTextures/IceSplit/ICE51.BMP' }
RTSBlock.materials[52] = new THREE.MeshLambertMaterial { map: new THREE.ImageUtils.loadTexture 'LegoRR0/World/WorldTextures/IceSplit/ICE52.BMP' }
RTSBlock.materials[53] = new THREE.MeshLambertMaterial { map: new THREE.ImageUtils.loadTexture 'LegoRR0/World/WorldTextures/IceSplit/ICE53.BMP' }
RTSBlock.materials[54] = new THREE.MeshLambertMaterial { map: new THREE.ImageUtils.loadTexture 'LegoRR0/World/WorldTextures/IceSplit/ICE54.BMP' }
RTSBlock.materials[55] = new THREE.MeshLambertMaterial { map: new THREE.ImageUtils.loadTexture 'LegoRR0/World/WorldTextures/IceSplit/ICE55.BMP' }

RTSBlock.materials[70] = new THREE.MeshLambertMaterial { map: new THREE.ImageUtils.loadTexture 'LegoRR0/World/WorldTextures/IceSplit/ICE70.BMP' }
RTSBlock.materials[76] = new THREE.MeshLambertMaterial { map: new THREE.ImageUtils.loadTexture 'LegoRR0/World/WorldTextures/IceSplit/ICE76.BMP' }
RTSBlock.materials[77] = new THREE.MeshLambertMaterial { map: new THREE.ImageUtils.loadTexture 'LegoRR0/World/WorldTextures/IceSplit/ICE77.BMP' }

RTSBlock.materials.ROOF = new THREE.MeshLambertMaterial { map: new THREE.ImageUtils.loadTexture 'LegoRR0/World/WorldTextures/ICEROOF.BMP' }

window.RTS.Block = RTSBlock
