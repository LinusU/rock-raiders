
class RTSBuilding extends RTS.Object
  constructor: (@map, @opts) ->
    super

    @block = @map.getBlock Math.floor(@opts.x), Math.floor(@opts.y)
    @block.hasBuilding = true

    [dx, dy] = @deltaXY()
    @entrance = @map.getBlock(Math.floor(@opts.x) + dx, Math.floor(@opts.y) + dy)
    @entrance.hasBuilding = true

  xyForEntrance: ->
    rand = -> Math.round(4 + Math.random() * 2)
    switch @opts.heading
      when 0 then [px, py] = [rand(), 9]
      when 90 then [px, py] = [9, rand()]
      when 180 then [px, py] = [rand(), 0]
      when 270 then [px, py] = [0, rand()]
      else assert false
    return [@entrance.opts.x * 10 + px, @entrance.opts.y * 10 + py]


window.RTS.Building = RTSBuilding
