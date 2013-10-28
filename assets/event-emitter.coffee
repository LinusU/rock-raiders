
class EventEmitter
  constructor: ->
    @_events = {}
  on: (ev, fn) ->
    @_events[ev] ||= []
    @_events[ev].push fn
  emit: (ev, data) ->
    (@_events[ev] || []).forEach (fn) -> fn data

window.EventEmitter = EventEmitter
