user = require './db/user'

module.exports = (app) ->
  
  app.get('/db/user/:handle', user.getByHandle)
  app.post('/db/user', user.post)
  app.put('/db/user/:handle', user.put)
  app.delete('/db/user/:handle', user.delete)