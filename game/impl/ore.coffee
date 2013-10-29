
geometry = new THREE.SphereGeometry(1.2)
material = new THREE.MeshLambertMaterial({ map: new THREE.ImageUtils.loadTexture 'LegoRR0/MiscAnims/Ore/Ore.bmp' })

class RROre extends RTS.Resource
  name: -> 'Ore'
  geometry: -> geometry
  material: -> material

window.RR.Ore = RROre
