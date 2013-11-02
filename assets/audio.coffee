
class GAudio
  constructor: ->
    @effects = {}
    @ctx = new (window.AudioContext || window.webkitAudioContext)
  registerEffect: (name, url) ->
    @effects[name] = {
      url: url
      buffer: null
    }
    xhr = new XMLHttpRequest
    xhr.open 'GET', url, true
    xhr.responseType = 'arraybuffer'
    xhr.onload = =>
      @ctx.decodeAudioData xhr.response, (buffer) =>
        @effects[name].buffer = buffer
    xhr.send()
  playEffect: (name, _loop = false) ->
    if @effects[name].buffer
      src = @ctx.createBufferSource()
      src.loop = _loop
      src.buffer = @effects[name].buffer
      src.connect @ctx.destination
      src.start 0
      return { stop: -> src.stop 0 }
    else
      # FIXME
      return { stop: -> }

window.GAudio = new GAudio
