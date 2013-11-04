
class RRInterface
  constructor: (@game) ->
    @mfQueue = 0
    @resQueue = { Ore: [], Crystal: [] }
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
    @text[0].textContent = ''
    @text[1].textContent = '0'
    @text[2].textContent = '0'
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
          @text[0].textContent = (if newVal > 0 then newVal else '')
          val = parseInt newVal
    do =>
      val = 0
      Object.defineProperty @, 'ore',
        enumerable: true
        configurable: true
        get: -> val
        set: (newVal) =>
          @text[1].textContent = newVal
          val = parseInt newVal
    do =>
      val = 0
      Object.defineProperty @, 'crystal',
        enumerable: true
        configurable: true
        get: -> val
        set: (newVal) =>
          @text[2].textContent = newVal
          val = parseInt newVal
    @mainMenu()
  demandResource: (type, work) ->
    @resQueue[type].push work
  depositResouce: (r) ->
    w = null
    for item in @resQueue[r.name()]
      if r.canWalkTo item.x, item.y
        w = item
        break
    if w isnt null
      @resQueue[r.name()].remove w
    else
      ts = r.findToolstation()
      if ts
        w = new RTS.Work { action: 'store-object', obj: r, building: ts }
    return w
  addWork: (w) ->
    @workQueue.enq w
  getWork: ->
    if @workQueue.size()
      @workQueue.deq()
    else
      null
  findWork: (pilot) ->
    for r in RTS.Resource.all
      if !(r.isPickedUpBy or r.predicted.isPickedUpBy or r.belongsToBuilding)
        w = new RTS.Work { action: 'pickup-object', obj: r }
        if pilot.canDoWork w
          w2 = @depositResouce r
          if w2
            w.nextWork = w2
            r.predicted.isPickedUpBy = pilot
            return w
    if @ore > 0
      for item in @resQueue.Ore
        ts = item.block.findToolstation()
        if ts
          @ore--
          w = new RTS.Work { action: 'withdraw-resource', type: 'ore', building: ts }
          w.nextWork = item
          @resQueue.Ore.remove item
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
  showBriefingPanel: (title, pages, cb) ->
    i = 0
    click = =>
      if ++i < pages.length
        win.querySelector('.text').textContent = pages[i]
      else
        @domElement.removeChild win
        cb null
    win = document.createElement 'div'
    win.className = 'rr-interface-briefing-panel'
    win.innerHTML = """
      <div class="title"></div>
      <div class="text"></div>
      <div class="btn-continue"></div>
    """
    win.addEventListener 'click', (e) -> e.stopPropagation()
    win.querySelector('.title').textContent = title
    win.querySelector('.text').textContent = pages[i]
    win.querySelector('.btn-continue').addEventListener 'click', click, false
    @domElement.appendChild win
  showHelpWindow: (text, cb) ->
    click = (val) =>
      @domElement.removeChild win
      cb null, val
    win = document.createElement 'div'
    win.className = 'rr-interface-help-window'
    win.innerHTML = """
      <div class="text"></div>
      <div class="btn-continue"></div>
      <div class="btn-close"></div>
    """
    win.addEventListener 'click', (e) -> e.stopPropagation()
    win.querySelector('.text').textContent = text
    win.querySelector('.btn-close').addEventListener 'click', (-> click false), false
    win.querySelector('.btn-continue').addEventListener 'click', (-> click true), false
    @domElement.appendChild win
  runAction: (action, ctx) ->
    switch action
      when 'drill-wall' then @addWork new RTS.Work { action: action, block: ctx, ordered: true }
      when 'blast-wall'
        ts = ctx.findToolstation()
        if ts isnt null
          w = new RTS.Work { action: 'withdraw-resource', type: 'dynamite', building: ts }
          w.nextWork = new RTS.Work { action: 'blast-wall', block: ctx }
          @addWork w
      when 'clear-rubble' then repeat 4, => @addWork new RTS.Work { action: action, block: ctx, ordered: true }
      when 'build-path' then ctx.demandPath()
      when 'pickup-object' then @addWork new RTS.Work { action: action, obj: ctx, ordered: true }
      when 'teleport-pilot' then @mfQueue++
      when 'drop-object' then ctx.demandWork new RTS.Work { action: action, pilot: ctx }
      when 'main-menu' then @game.selected.clear()
      when 'menu-building' then @setButtons []
      else NotImplemented()
    if action not in [ 'menu-building' ]
      @mainMenu()
  mainMenu: ->
    @setButtons [
      'teleport-pilot'
      'menu-building'
      'menu-small-vehicle'
      'menu-big-vehicle'
    ], null, false
  setButtons: (btns, ctx, showBack = true) ->
    cls = 'rr-interface-buttons-' + (btns.length) + (if showBack then '' else '-woback')
    @buttons.innerHTML = ''
    @buttons.className = 'rr-interface-buttons ' + cls
    if showBack then btns.unshift 'main-menu'
    btns.forEach (btn) =>
      div = document.createElement 'div'
      div.className = 'rr-interface-button rr-btn-' + btn
      div.addEventListener 'click', ((e) => @runAction(btn, ctx); e.stopPropagation()), false
      @buttons.appendChild div

window.RRInterface = RRInterface
