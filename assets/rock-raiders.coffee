
WIDTH = 640
HEIGHT = 480

Key =
  _pressed: {}
  LEFT: 65 #37
  UP: 87 #38
  RIGHT: 68 #39
  DOWN: 83 #40
  isDown: (keyCode) ->
    @_pressed[keyCode]
  relX: ->
    (if @_pressed[@LEFT] then -1 else 0) + (if @_pressed[@RIGHT] then 1 else 0)
  relY: ->
    (if @_pressed[@DOWN] then -1 else 0) + (if @_pressed[@UP] then 1 else 0)

window.addEventListener 'keyup', (event) ->
  delete Key._pressed[event.keyCode]
window.addEventListener 'keydown', (event) ->
  Key._pressed[event.keyCode] = true
window.addEventListener 'blur', (event) ->
  Key._pressed = {}

class Camera
  constructor: (@game) ->

    @distance = 35

    @camera = new THREE.PerspectiveCamera 50, (4/3), 1, 10000
    @camera.position.set @distance, @distance, 50
    @camera.lookAt new THREE.Vector3 0, 0, 0
    @camera.rotateOnAxis new THREE.Vector3(0, 0, 1), (Math.PI / 180) * 120

    @light = new THREE.PointLight 0xffffff, 1, @distance * 2
    @light.position.set @distance / 2, @distance / 2, 30
    @game.scene.add @light

  move: (dx, dy) ->

    _dx = (-dy - dx) / 2
    _dy = (dx + -dy) / 2

    @camera.position.x += _dx
    @camera.position.y += _dy
    @light.position.x += _dx
    @light.position.y += _dy

  moveTo: (x, y) ->
    @light.position.x = x + @distance / 2
    @light.position.y = y + @distance / 2
    @camera.position.x = x + @distance
    @camera.position.y = y + @distance

class RockRaiders
  constructor: (@div) ->

    @scene = new THREE.Scene()
    @selected = new RTS.Selected

    @renderer = new THREE.WebGLRenderer
    # @renderer = new THREE.CanvasRenderer

    @renderer.setSize WIDTH, HEIGHT
    @div.appendChild @renderer.domElement

    @interface = new RRInterface @
    @div.appendChild @interface.domElement

    @light = new THREE.AmbientLight 0x505050
    @scene.add @light

    @camera = new Camera @
    @mouse = new THREE.Vector2
    @projector = new THREE.Projector
    @raycaster = new THREE.Raycaster

    @div.addEventListener 'click', (event) =>
      style = window.getComputedStyle @div
      @mouse.x = ((event.pageX - @div.offsetLeft - parseInt(style.borderLeftWidth)) / WIDTH) * 2 - 1
      @mouse.y = -((event.pageY - @div.offsetTop - parseInt(style.borderTopWidth)) / HEIGHT) * 2 + 1
      @click()

    @map = new RTS.Map @
    @lastRender = Date.now()

    requestAnimationFrame => @tick()

  setCameraPos: (x, y) ->
    @camera.moveTo x * 10, y * 10

  tick: ->

    dt = Date.now() - @lastRender
    @lastRender = Date.now()

    RTS.Animation.tickAll dt

    @camera.move Key.relX() * (dt / 20), Key.relY() * (dt / 20)
    @render()

    # requestAnimationFrame => @tick()
    setTimeout (=> @tick()), Math.max((1000/30) - (Date.now() - @lastRender), 20)

  render: ->
    @renderer.render @scene, @camera.camera

  click: ->

    vector = new THREE.Vector3 @mouse.x, @mouse.y, 1
    @projector.unprojectVector vector, @camera.camera
    @raycaster.set @camera.camera.position, vector.sub(@camera.camera.position).normalize()

    intersects = @raycaster.intersectObjects @scene.children
    if intersects.length > 0
      intersects[0].object._on_click intersects[0].point

window.RockRaiders = RockRaiders
