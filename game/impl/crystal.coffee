
geometry = new THREE.SphereGeometry(1.2)
material = new THREE.MeshLambertMaterial({ map: new THREE.ImageUtils.loadTexture 'texture/Linus/Crystal.bmp' })

class RRCrystal extends RTS.Resource
  name: -> 'Crystal'
  geometry: -> geometry
  material: -> material

window.RR.Crystal = RRCrystal
