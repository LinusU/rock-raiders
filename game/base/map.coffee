
readMap = (data, fn) ->
  i = 14
  width = data[8]
  height = data[12]
  [0..height-1].map (y) ->
    [0..width-1].map (x) ->
      fn x, y, data[(i += 2)]

binaryRequest = (url, cb) ->
  xhr = new XMLHttpRequest
  xhr.responseType = "arraybuffer"
  xhr.open "GET", url, true
  xhr.onload = => cb null, new Uint8Array(xhr.response)
  xhr.send()

class RTSMap
  constructor: (@game) ->
    binaryRequest "LegoRR0/Levels/GameLevels/Level01/Surf_01.map", (err, data) => @loadSurf data
  fetchDugg: ->
    binaryRequest "LegoRR0/Levels/GameLevels/Level01/Dugg_01.map", (err, data) => @loadDugg data
  fetchCror: ->
    binaryRequest "LegoRR0/Levels/GameLevels/Level01/Cror_01.map", (err, data) => @loadCror data
  fetchOL: ->

    xhr = new XMLHttpRequest
    xhr.open "GET", "LegoRR0/Levels/GameLevels/Level01/01.ol", true
    xhr.onload = => @loadOL xhr.responseText
    xhr.send()

  getBlock: (x, y) ->
    row = @blocks[y]
    if row is undefined
      return null
    block = row[x]
    if block is undefined
      return null
    return block

  getWalkPath: (x1, y1, x2, y2) ->
    @finder.findPath x1, y1, x2, y2, @grid.clone()
  loadSurf: (data) ->

    @width = data[8]
    @height = data[12]
    @grid = new PF.Grid data[8] * 10, data[12] * 10
    @finder = new PF.AStarFinder allowDiagonal: true, dontCrossCorners: true
    @blocks = readMap data, (x, y, val) =>
      switch val
        when 0
          new RTS.Block @, { x: x, y: y, type: 'floor' }
        when 1
          new RTS.Block @, { x: x, y: y, type: 'wall', strength: 4 }
        when 2
          new RTS.Block @, { x: x, y: y, type: 'wall', strength: 3 }
        when 3
          new RTS.Block @, { x: x, y: y, type: 'wall', strength: 2 }
        when 4, 5
          new RTS.Block @, { x: x, y: y, type: 'wall', strength: 1 }
        when 6
          new RTS.Block @, { x: x, y: y, type: 'lava' }
        when 9
          new RTS.Block @, { x: x, y: y, type: 'water' }
        # 08 Ore Seam
        # 0A Energy Crystal Seam
        # 0B Recharge Seam
        else NotImplemented()

    @fetchDugg()

  loadDugg: (data) ->

    readMap data, (x, y, val) =>
      switch val
        when 0 then null
        when 1
          b = @getBlock x, y
          if b.opts.type is 'wall' then b.opts.type = 'floor'
        when 2
          b = @getBlock x, y
          b.partOfHiddenCavern = true
        else NotImplemented()

    @blocks.map (row) => row.map (block) => block.updateOpts()
    @blocks.map (row) => row.map (block) => block.createMesh()
    @fetchCror()

  loadCror: (data) ->

    readMap data, (x, y, val) =>
      switch val
        when 0 then null
        when 1, 3 then @blocks[y][x].resources.crystal += 1
        when 2, 4 then @blocks[y][x].resources.ore += 1
        when 5, 7 then @blocks[y][x].resources.crystal += 3
        when 6, 8 then @blocks[y][x].resources.ore += 3
        when 9, 11 then @blocks[y][x].resources.crystal += 5
        when 10, 12, 16 then @blocks[y][x].resources.ore += 5
        when 13, 19 then @blocks[y][x].resources.crystal += 11
        when 14, 20 then @blocks[y][x].resources.ore += 11
        when 17, 23 then @blocks[y][x].resources.crystal += 15
        when 18, 24 then @blocks[y][x].resources.ore += 15
        else NotImplemented()

    @fetchOL()

  loadOL: (data) ->
    objs = {}
    regex1 = /([a-z0-9]+) \{([^\}]+)\}/ig
    regex2 = /[ \t]*([a-z]+)[ \t]+([a-z0-9\.]+)/ig
    data.substring(7, data.length - 1).replace regex1, =>
      opts = {}
      arguments[2].replace regex2, =>
        opts[arguments[1]] = arguments[2]
      opts.x = parseFloat(opts.xPos) - 1
      opts.y = parseFloat(opts.yPos) - 1
      opts.heading = parseFloat opts.heading
      delete opts.xPos
      delete opts.yPos
      LOG JSON.stringify opts
      switch opts.type
        when 'TVCamera'
          @game.setCameraPos opts.x, opts.y
        when 'SmallSpider', 'Pilot', 'Toolstation'
          objs[arguments[1]] = new RR[opts.type] @, opts
        else NotImplemented()

window.RTS.Map = RTSMap
