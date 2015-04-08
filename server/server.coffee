require('./globals').setup()

winston = require 'winston'
morgan = require 'morgan'
cookieParser = require 'cookie-parser'
bodyParser = require 'body-parser'

mongoose = require 'mongoose'
Grid = require 'gridfs-stream'
express = require 'express'
compressible = require 'compressible'
path = require 'path'
useragent = require 'express-useragent'
fs = require 'graceful-fs'
http = require 'http'

config = require './server-config'
routes = require './routes'

module.exports.start = (readyCallback) ->
  return if @server
  
  #- setup logging
  winston.remove(winston.transports.Console)
  winston.add(winston.transports.Console,
    colorize: true,
    timestamp: true
  )
  
  
  #- connect to db
#  dbName = config.mongo.db
#  address = "#{config.mongo.host}:#{config.mongo.port}"
#  if config.mongo.username and config.mongo.password
#    address = "#{config.mongo.username}:#{config.mongo.password}@#{address}"
#  address = "mongodb://#{address}/#{dbName}"
#  
#  winston.info "DB connecting to #{address}"
#  mongoose.connect address
#  mongoose.connection.once 'open', -> 
#    Grid.gfs = Grid(mongoose.connection.db, mongoose.mongo)
  
  
  #- express creation, config
  app = express()
  app.set 'port', config.port
  app.set 'env', if config.isProduction then 'production' else 'development'
  app.use(express.static(path.join(__dirname, '../public')))
  app.use(express.static(path.join(__dirname, '../bower_components/bootstrap')))
  app.use(morgan('dev'))
  app.use(useragent.express())
  app.use(cookieParser(config.cookie_secret))
  app.use(bodyParser.json())

  
  #- passport middlware
  authentication = require('passport')
  app.use(authentication.initialize())
  app.use(authentication.session())


  #- setup routes
  routes(app)

  
  #- Serve index.html
  try
    mainHTML = fs.readFileSync(path.join(__dirname, '../public', 'index.html'), 'utf8')
  catch e
    winston.error "Error modifying index.html: #{e}"

  app.all '*', (req, res) ->
    # insert the user object directly into the html so the application can have it immediately. Sanitize </script>
#      data = mainHTML.replace('"userObjectTag"', JSON.stringify(UserHandler.formatEntity(req, req.user)).replace(/\//g, '\\/'))
    res.header 'Cache-Control', 'no-cache, no-store, must-revalidate'
    res.header 'Pragma', 'no-cache'
    res.header 'Expires', 0
    res.status(200).send(mainHTML)

  @server = http.createServer(app).listen app.get('port'), ->
    winston.info('Express server listening on port ' + app.get('port'))
    readyCallback?()
    
    
module.exports.close = ->
  @server?.close()
  @server = null