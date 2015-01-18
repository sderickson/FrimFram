# TODO: add another endpoint which reports all the specs, which the client can use to display
# to the user and so it can know what files to offer to run
# TODO: build a client which uses these two endpoints to provide the same sort of nice
# test automation you can see in the browser

module.exports.get = (req, res) ->
  # TODO: have this only able to run on a dev server
  # TODO: have this accept GET arguments to limit what tests get run
  spawn = require('child_process').spawn
  jasmineNode = spawn('node_modules/jasmine-node/bin/jasmine-node', ['test/server/', '--coffee', '--captureExceptions', '--forceexit'])
  lines = []
  storeData = (data) -> lines.push(String(data))
  jasmineNode.stdout.on('data', storeData)
  jasmineNode.stderr.on('data', storeData)
  jasmineNode.on('exit', (exitCode) ->
    res.send(200, lines.join(''))
  )
