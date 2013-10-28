
assman = require 'assman'
express = require 'express'

assman.top __dirname + '/'

assman.register 'css', 'game', [ 'assets/game.styl' ]
assman.register 'html', 'game', [ 'assets/game.jade' ]
assman.register 'js', 'rock-raiders', [

  'vendor/three.min.js'
  'vendor/pathfinding-browser.min.js'
  'vendor/priorityqueue.min.js'

  'game/init.coffee'

  'game/base/block.coffee'
  'game/base/map.coffee'
  'game/base/object.coffee'
  'game/base/select.coffee'
  'game/base/work.coffee'

  'game/base/building.coffee'
  'game/base/resource.coffee'
  'game/base/unit.coffee'

  'game/impl/crystal.coffee'
  'game/impl/ore.coffee'
  'game/impl/pilot.coffee'
  'game/impl/small-spider.coffee'
  'game/impl/toolstation.coffee'

  'assets/interface.coffee'
  'assets/rock-raiders.coffee'
]

app = express()
app.use assman.middleware

app.use '/levels', express.static __dirname + '/levels'
app.use '/texture', express.static __dirname + '/texture'

app.get '/', (req, res) ->
  res.redirect '/game.html'

app.listen 4800
