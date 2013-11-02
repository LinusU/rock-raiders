
assman = require 'assman'
express = require 'express'

assman.top __dirname + '/'

assman.register 'css', 'game', [ 'assets/game.styl' ]
assman.register 'html', 'game', [ 'assets/game.jade' ]
assman.register 'js', 'rock-raiders', [

  'vendor/three.min.js'
  'vendor/pathfinding-browser.min.js'
  'vendor/priorityqueue.min.js'

  'assets/audio.coffee'

  'game/init.coffee'

  'game/base/map.coffee'
  'game/base/object.coffee'
  'game/base/path.coffee'
  'game/base/select.coffee'
  'game/base/work.coffee'

  'game/base/block.coffee'
  'game/base/building.coffee'
  'game/base/resource.coffee'
  'game/base/unit.coffee'

  'game/impl/crystal.coffee'
  'game/impl/dynamite.coffee'
  'game/impl/ore.coffee'
  'game/impl/pilot.coffee'
  'game/impl/small-spider.coffee'
  'game/impl/toolstation.coffee'

  'assets/interface.coffee'
  'assets/rock-raiders.coffee'
]

app = express()
app.use assman.middleware

app.use '/LegoRR0', express.static __dirname + '/LinusRR'
app.use '/LegoRR0', express.static __dirname + '/LegoRR0'
app.use '/LegoRR1', express.static __dirname + '/LegoRR1'

app.get '/', (req, res) ->
  res.redirect '/game.html'

app.listen 4800
