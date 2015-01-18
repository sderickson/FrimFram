module.exports = (app) ->

  user = require './db/user'
  
  app.get('/db/user/:handle', user.getByHandle)
  app.post('/db/user', user.post)
  app.put('/db/user/:handle', user.put)
  app.delete('/db/user/:handle', user.delete)
  # TODO: add patch

  test = require './test'
  
  app.get('/test', test.get)