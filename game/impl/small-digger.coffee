
geometry = new THREE.CubeGeometry(4, 8, 2)
material = new THREE.MeshLambertMaterial({ map: new THREE.ImageUtils.loadTexture 'LegoRR0/Vehicles/SmallDigger/Heli-truck-toptex.bmp' })

class RRSmallDigger extends RTS.Object
  geometry: -> geometry
  material: -> material
  _updateMesh: ->
    super
    @mesh.position.z = 2.5

window.RR.SmallDigger = RRSmallDigger
