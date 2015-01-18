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
    @serverStarted = true
    require('../../server/projRequire')
    config = projRequire 'server/server-config'
    config.runningTests = true
    config.port = 3001

    spawn = require('child_process').spawn
    server = projRequire('server/server')
    server.start =>
      @serverReady = true
      for callback in @callbacks
        callback()