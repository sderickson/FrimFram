# This file sets everything up for tests. It needs to be imported before anything
# else (to set up globals) and no test should run until after onReady has called back.

require('../../server/globals').setup()

#- Setup mockgoose. If any Model is imported before this happens, bad things happen.
mongoose = require 'mongoose'
mockgoose = require 'mockgoose'
mockgoose(mongoose)


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
  config = rootRequire 'server/server-config'
  config.runningTests = true
  config.port = 3001
  
  spawn = require('child_process').spawn
  server = rootRequire('server/server')
  server.start =>
    @serverReady = true
    callback() for callback in @callbacks
