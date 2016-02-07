
loader = new THREE.TextureLoader
geometry = new THREE.BoxGeometry(3, 1.5, 1.5)
material = new THREE.MeshLambertMaterial({ map: loader.load 'LegoRR0/MiscAnims/Dynamite/Dinamite.bmp' })

GAudio.registerEffect 'dynamite-fuse', 'LegoRR0/Sounds/Minifigure/dynamite.wav'
GAudio.registerEffect 'dynamite-expl', 'LegoRR0/Sounds/gen_Explode2.wav'

class RRDynamite extends RTS.Object
  name: -> 'Dynamite'
  geometry: -> geometry
  material: -> material
  lightFuse: (block) ->
    GAudio.playEffect 'dynamite-fuse'
    setTimeout (=>
      GAudio.playEffect 'dynamite-expl'
      block.collapse()
      @destroy()
    ), 5000

window.RR.Dynamite = RRDynamite
