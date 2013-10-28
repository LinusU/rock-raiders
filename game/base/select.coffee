
class RTSSelected
  constructor: ->

    @_obj = null
    @_type = null

    Object.defineProperty @, 'pilot',
      get: => (if @_type is 'pilot' then @_obj else null)
      set: (v) => @set 'pilot', v

    Object.defineProperty @, 'block',
      get: => (if @_type is 'block' then @_obj else null)
      set: (v) => @set 'block', v

  clear: ->
    @_obj = null
    @_type = null

  set: (type, obj) ->
    if obj is null
      @clear()
    else
      @_type = type
      @_obj = obj

window.RTS.Selected = RTSSelected
