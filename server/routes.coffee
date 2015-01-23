module.exports = (app) ->

  user = require './db/user'
  app.get('/db/user/:handle', user.getByHandle)
  app.post('/db/user', user.post)
  app.put('/db/user/:handle', user.put)
  app.delete('/db/user/:handle', user.delete)
  # TODO: add patch

  test = require './server-test'
  app.get('/server-test/list', test.listServerTests)
  app.post('/server-test/run', test.runServerTests)
  app.post('/server-test/setup', test.setup)
  app.get('/server-test/running', test.running)
  app.post('/server-test/teardown', test.teardown)
  