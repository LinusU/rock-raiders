
class RTSWork
  constructor: (opts) ->

    for key in Object.keys opts
      @[key] = opts[key]

    if @x is undefined or @y is undefined
      rand = -> 3 + Math.random() * 4
      switch @action
        when 'drop-object'
          [@x, @y] = [null, null]
        when 'drill-wall'
          [@x, @y] = @block.xyForDrillWall()
        when 'clear-rubble'
          [@x, @y] = [Math.round(@block.opts.x * 10 + rand()), Math.round(@block.opts.y * 10 + rand())]
        when 'pickup-object', 'collect-resource'
          [@x, @y] = [Math.round(@obj.opts.x * 10), Math.round(@obj.opts.y * 10)]
        when 'store-object'
          assert @building
          [@x, @y] = @building.xyForEntrance()
        else
          throw new Error('FIXME')

    if @priority is undefined
      @priority = 5
      switch @action
        when 'drill-wall' then 12
        when 'clear-rubble' then 6
        when 'pickup-object' then 8
        when 'collect-resource' then 9
        when 'store-object' then 10
      if @ordered
        @priority += 20

    if @action is 'collect-resource'
      @nextWork = new RTSWork { action: 'store-object', obj: @obj, building: @building }

  setBuilding: (building) ->
    assert @action is 'store-object'
    @building = building
    [@x, @y] = @building.xyForEntrance()

window.RTS.Work = RTSWork
