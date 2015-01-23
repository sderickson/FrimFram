config = rootRequire 'server/server-config'
respond = rootRequire 'server/respond'
fs = require 'fs'
spawn = require('child_process').spawn
xml2js = require 'xml2js'
async = require 'async'
gaze = require 'gaze'
WebSocketServer = require('ws').Server

#- Server test finding

serverTestsPath = rootPath = require.main.filename.replace('/index.js', '/test/server/')

findTestPaths = ->
  paths = ['']
  results = []
  while paths.length
    path = paths.pop()
    results.push(path)
    files = fs.readdirSync(serverTestsPath + path)
    for file in files
      if file.indexOf('.spec.') > -1
        results.push(path + file)
      stat = fs.statSync(serverTestsPath + path + file)
      if stat.isDirectory()
        paths.push(path + file + '/')
  return results

serverTestPaths = findTestPaths() unless config.isProduction or config.runningTests


#- GET /server-test/list

module.exports.listServerTests = (req, res) ->
  if config.isProduction
    return respond.forbidden(res, {message: 'Only allowed on local dev machines.'})

  res.json(serverTestPaths)


#- POST /server-test/run
  
module.exports.runServerTests = (req, res) ->
  # Since I'm using this endpoint just as a fancy way to run and view test results,
  # I'm not going to bother with using async fs calls.

  if config.isProduction
    return respond.forbidden(res, {message: 'Only allowed on local dev machines.'})

  givenPath = req.body.path or ''
  
  if givenPath not in serverTestPaths
    return respond.unprocessableEntity(res, {message: 'Given path does not match any test files.'})

  # clear the reports directory
  reportDir = rootDir + 'reports/'
  files = fs.readdirSync(reportDir)
  for file in files
    fs.unlinkSync(reportDir+file)

  path = 'test/server/' + givenPath
  jasmineNode = spawn('node_modules/jasmine-node/bin/jasmine-node', [path, '--coffee', '--captureExceptions', '--forceexit', '--junitreport'])

  consoleError = []
  jasmineNode.stderr.on('data', (data) -> consoleError.push(String(data)))

  # TODO: Try to put this into an async.waterfall or something like it. Avoid callback hell!
  response = { rootDir: rootDir }
  jasmineNode.on 'exit', (exitCode) ->
    if consoleError = consoleError.join('')
      response.consoleError = consoleError
      return respond.ok(res, response)
    files = fs.readdirSync(reportDir)
    files = (reportDir + f for f in files)
    async.map files, fs.readFile, (err, results) ->
      return respond.internalServerError(res, {message: 'Error reading reports.', error: err}) if err
      async.map results, xml2js.parseString, (err, reports) ->
        return respond.internalServerError(res, {message: 'Error parsing reports.', error: err}) if err
        response.reports = reports
        respond.ok(res, response)
        

#- POST /server-test/setup

module.exports.setup = (req, res) ->
  return respond.noContent(res) if @inTestMode

  # disable nodemon, hackily
  process.on 'SIGUSR2', _.noop
  console.warn 'Nodemon no longer has power here. The server will not auto-reload until forced.'

  # setup a socket server for the server client to dial into
  wss = new WebSocketServer { port: 3002 }, ->
    return respond.noContent(res)

  # watch all the files ourselves. When there are changes, notify clients via websocket
  gaze ['server/**', 'test/server/**', 'app/schemas/**'], ->
    @on 'all', (event, filepath) ->
      module.exports.lastChange = new Date().getTime()
      wss.clients.forEach (client) -> client.send('1')
    # TODO: Recognize when a file is changed, created or deleted, refresh the list, and tell the client to update.
    # TODO: It broke down when I renamed a folder. Make it not do that.

  @inTestMode = true


#- GET /server-test/running

module.exports.running = (req, res) ->
  return respond.ok(res, !!@inTestMode)
  
  
#- POST /server-test/teardown

module.exports.teardown = (req, res) ->
  respond.noContent(res)
  if @inTestMode
    # let nodemon continue the kililng process, hackily
    process.removeListener 'SIGUSR2', _.noop
    process.kill(process.pid, 'SIGUSR2')