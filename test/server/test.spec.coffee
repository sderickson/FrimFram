config = require('../../server/server-config')
config.runningTests = true
config.port = 3001
request = require 'request'

makeURL = (path) -> "http://localhost:#{config.port}#{path}"

describe 'POST /db/user', ->
  it 'creates a new user', (done) ->
    request.post makeURL('/db/user'), (err, res, body) ->
      expect(res.statusCode).toBe(422)
      done()