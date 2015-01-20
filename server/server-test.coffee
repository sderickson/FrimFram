config = projRequire 'server/server-config'
respond = projRequire 'server/respond'
fs = require 'fs'
spawn = require('child_process').spawn


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
  if config.isProduction
    return respond.forbidden(res, {message: 'Only allowed on local dev machines.'})

  givenPath = req.body.path or ''
  
  if givenPath not in serverTestPaths
    return respond.unprocessableEntity(res, {message: 'Given path does not match any test files.'})

  path = 'test/server/' + givenPath
    
  jasmineNode = spawn('node_modules/jasmine-node/bin/jasmine-node', [path, '--coffee', '--captureExceptions', '--forceexit', '--junitreport'])
  lines = []
  storeData = (data) -> lines.push(String(data))
  jasmineNode.stdout.on('data', storeData)
  jasmineNode.stderr.on('data', storeData)
  jasmineNode.on('exit', (exitCode) ->
    res.send(200, lines.join(''))
  )
