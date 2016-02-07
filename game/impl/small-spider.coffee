
geometry = new THREE.BoxGeometry(1.5, 1.5, 1)
material = new THREE.MeshLambertMaterial({ color: 0xaaaa00 })

class RRSmallSpider extends RTS.Object
  geometry: -> geometry
  material: -> material
  click: ->
    @destroy()


window.RR.SmallSpider = RRSmallSpider
