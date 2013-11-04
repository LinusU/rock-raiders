
class RTSAnimation
  @_list: []
  @tickAll: (dt) ->
    # Reverse loop so animations can remove themselves
    i = RTSAnimation._list.length
    while (i--)
      RTSAnimation._list[i].tick(dt)
  constructor: ->
    RTSAnimation._list.push @
  destroy: ->
    RTSAnimation._list.remove @
  tick: ->
    AbstractMethod()

window.RTS.Animation = RTSAnimation
