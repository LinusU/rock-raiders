
class RTSWork
  constructor: (opts) ->

    for key in Object.keys opts
      @[key] = opts[key]

    if @x is undefined or @y is undefined
      rand = -> 3 + Math.random() * 4
      switch @action
        when 'drop-object'
          [@x, @y] = [null, null]
        when 'drill-wall', 'blast-wall'
          assert @block
          [@x, @y] = @block.xyForDrillWall()
        when 'clear-rubble', 'build-path', 'deposit-resource'
          assert @block
          [@x, @y] = [Math.round(@block.opts.x * 10 + rand()), Math.round(@block.opts.y * 10 + rand())]
        when 'pickup-object'
          assert @obj
          [@x, @y] = [Math.round(@obj.opts.x * 10), Math.round(@obj.opts.y * 10)]
        when 'store-object', 'withdraw-resource'
          assert @building
          [@x, @y] = @building.xyForEntrance()
        else NotImplemented()

    if @priority is undefined
      @priority = 5
      switch @action
        when 'drill-wall', 'blast-wall', 'withdraw-resource' then 12
        when 'clear-rubble' then 6
        when 'pickup-object' then 8
        when 'store-object' then 9
      if @ordered
        @priority += 20

  getFollowUp: ->
    # FIXME: When clearing rubble, clear all rubble, then collect the ore
    @nextWork

  setBuilding: (building) ->
    assert @action is 'store-object'
    @building = building
    [@x, @y] = @building.xyForEntrance()

window.RTS.Work = RTSWork
