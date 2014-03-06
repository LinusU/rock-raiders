
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

textRequest = (url, cb) ->
  xhr = new XMLHttpRequest
  xhr.open "GET", url, true
  xhr.onload = => cb null, xhr.responseText
  xhr.send()

class RTSMap
  constructor: (@game) ->
    @name =
      long: 'Level04'
      short: '04'
    binaryRequest "LegoRR0/Levels/GameLevels/#{@name.long}/Surf_#{@name.short}.map", (err, data) => @loadSurf data
  fetchDugg: ->
    binaryRequest "LegoRR0/Levels/GameLevels/#{@name.long}/Dugg_#{@name.short}.map", (err, data) => @loadDugg data
  fetchCror: ->
    binaryRequest "LegoRR0/Levels/GameLevels/#{@name.long}/Cror_#{@name.short}.map", (err, data) => @loadCror data
  fetchOL: ->
    textRequest "LegoRR0/Levels/GameLevels/#{@name.long}/#{@name.short}.ol", (err, data) => @loadOL data
  fetchStrings: ->
    textRequest "LegoRR1/Languages/ObjectiveText.txt", (err, data) => @loadStrings data
  getBlock: (x, y) ->
    row = @blocks[y]
    if row is undefined
      return null
    block = row[x]
    if block is undefined
      return null
    return block

  getWalkPath: (x1, y1, x2, y2) ->
    points = @finder.findPath x1, y1, x2, y2, @grid.clone()
    if points.length > 0 then new RTS.Path(@, points) else null
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
        when 8
          new RTS.Block @, { x: x, y: y, type: 'wall', strength: 1, stock: 4, seam: 'ore' }
        when 10
          new RTS.Block @, { x: x, y: y, type: 'wall', strength: 1, stock: 4, seam: 'crystal' }
        when 11
          new RTS.Block @, { x: x, y: y, type: 'wall', strength: 4, seam: 'recharge' }
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
        when 'PowerCrystal'
          objs[arguments[1]] = new RR.Crystal @, opts
        when 'SmallSpider', 'Pilot', 'Toolstation', 'SmallDigger'
          objs[arguments[1]] = new RR[opts.type] @, opts
        when 'SmallTruck'
          # FIXME: Transport Truck
          NotImplemented()
        when 'Upgrade'
          # FIXME: Upgrade Station
          NotImplemented()
        when 'Powerstation'
          # FIXME: Power Station
          NotImplemented()
        else
          LOG 'Not implemented item: ' + opts.type
          NotImplemented()
    @fetchStrings()
  loadStrings: (data) ->

    r1 = /\[([A-Za-z0-9_]+)\]/
    r2 = /([A-Za-z]+):[\t ]*(.*)/

    mine = false
    @strings = {}

    for line in data.split '\n'
      if (m = r1.exec line)
        mine = (m[1] is @name.long)
      if mine and (m = r2.exec line)
        @strings[m[1]] = m[2]

    @loadFinish()
  loadFinish: ->
    # MAYBE @blocks.map (row) => row.map (block) => block.updateOpts()
    @blocks.map (row) => row.map (block) => block.refreshMesh()
    @game.interface.showBriefingPanel 'Mission Objective', @strings['Objective'].split('\\a'), ->

window.RTS.Map = RTSMap
