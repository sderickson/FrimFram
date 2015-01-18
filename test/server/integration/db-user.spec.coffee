request = require 'request'
utils = require '../utils'
url = utils.makeURL('/db/user')

describe 'POST /db/user', ->
  it 'returns 422 if not enough data is provided to create a user', (done) ->
    request.post url, (err, res, body) ->
      expect(res.statusCode).toBe(422)
      done()
      
  it 'returns 201 if enough data is provided', (done) ->
    json = { email: 'something@gmail.com', name: 'Mr FooBar', password: 'password' }
    request.post { uri: url, json: json}, (err, res, body) ->
      expect(res.statusCode).toBe(201)
      done()
      
  