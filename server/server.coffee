log = require 'winston'
require './projRequire'

# TOGO: Where should this go?
do (setupGlobals = this) ->
  GLOBAL._ = require 'lodash'
  _.str = require 'underscore.string'
  _.mixin _.str.exports()
  global.tv4 = require 'tv4' # required for TreemaUtils to work

module.exports.startServer = ->
  
  #- setup logging
  log.remove(log.transports.Console)
  log.add(log.transports.Console,
    colorize: true,
    timestamp: true
  )

  
  #- connect to db
  Grid = require 'gridfs-stream'
  mongoose = require 'mongoose'
  config = projRequire 'server/server-config'

  dbName = config.mongo.db
  address = config.mongo.host + ':' + config.mongo.port
  if config.mongo.username and config.mongo.password
    address = config.mongo.username + ':' + config.mongo.password + '@' + address
  address = "mongodb://#{address}/#{dbName}"
  
  log.info "Connecting to Mongo with connection string #{address}"
  mongoose.connect address
  mongoose.connection.once 'open', -> Grid.gfs = Grid(mongoose.connection.db, mongoose.mongo)
  
  
  #- express creation, config
  express = require 'express'
  app = express()
  app.set('port', config.port)
  app.set('env', if config.isProduction then 'production' else 'development')

  
  #- express middleware
  compressible = require 'compressible'
  if config.isProduction

    productionLogging = (tokens, req, res) ->
      status = res.statusCode
      color = 32
      if status >= 500 then color = 31
      else if status >= 400 then color = 33
      else if status >= 300 then color = 36
      elapsed = (new Date()) - req._startTime
      elapsedColor = if elapsed < 500 then 90 else 31
      if (status isnt 200 and status isnt 204 and status isnt 304 and status isnt 302) or elapsed > 500
        return "\x1b[90m#{req.method} #{req.originalUrl} \x1b[#{color}m#{res.statusCode} \x1b[#{elapsedColor}m#{elapsed}ms\x1b[0m"
      null
    
    express.logger.format('prod', productionLogging)
    app.use(express.logger('prod'))
    app.use express.compress filter: (req, res) ->
      return false if req.headers.host is 'codecombat.com'  # Cloudflare will gzip it for us on codecombat.com
      compressible res.getHeader('Content-Type')
  else
    app.use(express.logger('dev'))

  path = require 'path'
  useragent = require 'express-useragent'
  app.use(express.static(path.join(__dirname, '../public')))
  app.use(useragent.express())

  app.use(express.favicon())
  app.use(express.cookieParser(config.cookie_secret))
  app.use(express.bodyParser())
  app.use(express.methodOverride())
  app.use(express.cookieSession({secret:'defenestrate'}))


  #- passport middlware
#  authentication = require('passport')
#  app.use(authentication.initialize())
#  app.use(authentication.session())


  # TODO: setup api routes

  
  #- Setup main.html
  fs = require 'graceful-fs'
  app.all '*', (req, res) ->
    fs.readFile path.join(__dirname, '../public', 'main.html'), 'utf8', (err, data) ->
      log.error "Error modifying main.html: #{err}" if err
      # insert the user object directly into the html so the application can have it immediately. Sanitize </script>
#      data = data.replace('"userObjectTag"', JSON.stringify(UserHandler.formatEntity(req, req.user)).replace(/\//g, '\\/'))
      res.header 'Cache-Control', 'no-cache, no-store, must-revalidate'
      res.header 'Pragma', 'no-cache'
      res.header 'Expires', 0
      res.send 200, data
  
  
  http = require 'http'
  http.createServer(app).listen(app.get('port'))
  log.info('Express SSL server listening on port ' + app.get('port'))
  app

  