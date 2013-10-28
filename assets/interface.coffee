
class RRInterface
  constructor: (@game) ->
    @mfQueue = 0
    @workQueue = new PriorityQueue (a, b) -> a.priority - b.priority
    @domElement = document.createElement 'div'
    @domElement.className = 'rr-interface'
    @buttons = document.createElement 'div'
    @buttons.className = 'rr-interface-buttons'
    @domElement.appendChild @buttons
    @text = [
      document.createElement('span')
      document.createElement('span')
      document.createElement('span')
    ]
    @text[0].className = 'rr-interface-mf'
    @text[1].className = 'rr-interface-ore'
    @text[2].className = 'rr-interface-crystal'
    @text[0].innerText = ''
    @text[1].innerText = 0
    @text[2].innerText = 0
    @domElement.appendChild @text[0]
    @domElement.appendChild @text[1]
    @domElement.appendChild @text[2]
    do =>
      val = 0
      Object.defineProperty @, 'mfQueue',
        enumerable: true
        configurable: true
        get: -> val
        set: (newVal) =>
          @text[0].innerText = (if newVal > 0 then newVal else '')
          val = parseInt newVal
    do =>
      val = 0
      Object.defineProperty @, 'ore',
        enumerable: true
        configurable: true
        get: -> val
        set: (newVal) =>
          @text[1].innerText = newVal
          val = parseInt newVal
    do =>
      val = 0
      Object.defineProperty @, 'crystal',
        enumerable: true
        configurable: true
        get: -> val
        set: (newVal) =>
          @text[2].innerText = newVal
          val = parseInt newVal
    @mainMenu()
  addWork: (w) ->
    @workQueue.enq w
  getWork: ->
    if @workQueue.size()
      @workQueue.deq()
    else
      null
  findWork: (pilot) ->
    for r in RTS.Resource.all
      if !(r.isPickedUpBy or r.predicted.isPickedUpBy)
        ts = r.findToolstation()
        if ts
          w = new RTS.Work { action: 'collect-resource', obj: r, building: ts }
          if pilot.canDoWork w
            r.predicted.isPickedUpBy = pilot
            return w
    for b in RTS.Block.allWithRubble
      if b.predicted.rubble is undefined or b.predicted.rubble > 0
        w = new RTS.Work { action: 'clear-rubble', block: b }
        if pilot.canDoWork w
          if b.predicted.rubble is undefined
            b.predicted.rubble = b.opts.rubble - 1
          else
            b.predicted.rubble--
          return w
    return null
  runAction: (action, ctx) ->
    switch action
      when 'drill-wall' then @addWork new RTS.Work { action: action, block: ctx, ordered: true }
      when 'clear-rubble' then [0..3].map => @addWork new RTS.Work { action: action, block: ctx, ordered: true }
      when 'build-path' then @addWork new RTS.Work { action: action, block: ctx, ordered: true }
      when 'pickup-object' then @addWork new RTS.Work { action: action, obj: ctx, ordered: true }
      when 'teleport-pilot' then @mfQueue++
      when 'drop-object' then ctx.demandWork new RTS.Work { action: action, pilot: ctx }
      when 'main-menu' then @game.selected.clear()
      when 'menu-building' then @setButtons [ 'main-menu' ]
      else NotImplemented()
    if action not in [ 'menu-building' ]
      @mainMenu()
  mainMenu: ->
    @setButtons [
      'teleport-pilot'
      'menu-building'
    ], null
  setButtons: (btns, ctx) ->
    @buttons.innerHTML = ''
    btns.forEach (btn) =>
      div = document.createElement 'div'
      div.className = 'rr-interface-button rr-btn-' + btn
      div.addEventListener 'mousedown', ((e) => @runAction(btn, ctx); e.stopPropagation()), false
      @buttons.appendChild div

window.RRInterface = RRInterface
