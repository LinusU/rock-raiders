
geometry = new THREE.CubeGeometry(3, 1.5, 1.5)
material = new THREE.MeshLambertMaterial({ map: new THREE.ImageUtils.loadTexture 'LegoRR0/MiscAnims/Dynamite/Dinamite.bmp' })

class RRDynamite extends RTS.Object
  name: -> 'Dynamite'
  geometry: -> geometry
  material: -> material
  lightFuse: (block) ->
    setTimeout (=>
      block.collapse()
      @destroy()
    ), 5000

window.RR.Dynamite = RRDynamite
