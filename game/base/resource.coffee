
class RTSResource extends RTS.Object
  @all: []
  constructor: (@map, @opts) ->
    @opts.heading = Math.random() * 360
    super
    RTSResource.all.push @
  destroy: ->
    RTSResource.all.remove @
    super
  click: ->
    if @map.game.selected.pilot
      @map.game.selected.pilot.demandWork new RTS.Work { action: 'pickup-object', obj: @ }
      @map.game.selected.clear()
      @map.game.interface.mainMenu()
    else
      @map.game.interface.setButtons [ 'pickup-object' ], @

window.RTS.Resource = RTSResource
