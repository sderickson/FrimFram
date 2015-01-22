module.exports.callbacks = []

module.exports.serverStarted = false
module.exports.serverReady = false

module.exports.onReady = (done) ->
  # TODO: use promises instead?
  if @serverReady
    done()
  else
    @callbacks.push done
  
  if not @serverStarted
    try
      @startServer()
    catch e
      console.error "Failed to start test server.", e.stack
      throw e

module.exports.startServer = ->
  @serverStarted = true
  require('../../server/rootRequire')
  config = rootRequire 'server/server-config'
  config.runningTests = true
  config.port = 3001
  
  spawn = require('child_process').spawn
  server = rootRequire('server/server')
  server.start =>
    @serverReady = true
    callback() for callback in @callbacks
