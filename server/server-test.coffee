config = projRequire 'server/server-config'
respond = projRequire 'server/respond'
fs = require 'fs'
spawn = require('child_process').spawn
xml2js = require 'xml2js'
async = require 'async'

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

  # TODO: Try to put this into an async.waterfall or something like it. Avoid callback hell!
  jasmineNode.on 'exit', (exitCode) ->
    files = fs.readdirSync(reportDir)
    files = (reportDir + f for f in files)
    async.map files, fs.readFile, (err, results) ->
      return respond.internalServerError(res, {message: 'Error reading reports.', error: err}) if err
      async.map results, xml2js.parseString, (err, results) ->
        return respond.internalServerError(res, {message: 'Error parsing reports.', error: err}) if err
        suites = (obj.testsuites.testsuite for obj in results)
        suites = _.flatten(suites)
        respond.ok(res, suites)
