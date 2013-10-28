
window.RTS = {}
window.RR = {}

# I'm sorry but I really like this one
window.repeat = (x, fn) ->
  while x-- then do fn
  return

# Hmm, and this one, I'm evil!
Object.defineProperty Array::, 'remove',
  enumerable: false
  configurable: false
  get: -> (item) ->
    @splice(idx, 1) if ~(idx = @indexOf item); @

class AssertionError extends Error
  constructor: ->
    e = super
    @name = 'AssertionError'
    @message = e.message

class NotImplementedError extends Error
  constructor: ->
    e = super
    @name = 'NotImplementedError'
    @message = e.message

window.NotImplemented = (msg) ->
  throw new NotImplementedError msg

window.assert = (ok) ->
  throw new AssertionError('assertion failed') unless ok
