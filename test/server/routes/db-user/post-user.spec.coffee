main = require '../../main'
request = require 'request'
utils = require '../../utils'
url = utils.makeURL('/db/user')

describe 'POST /db/user', ->

  beforeEach (done) -> main.onReady -> done()

  it 'returns 422 if not enough data is provided to create a user', (done) ->
    request.post url, (err, res, body) ->
      expect(res.statusCode).toBe(422)
      done()
      
  it 'returns 201 if enough data is provided', (done) ->
    # TODO: restructure main to have it set up projRequire and the server globals first thing
    # so this projRequire can go at the top of the file. 
    User = projRequire 'server/models/User'
    json = { email: 'something@gmail.com', name: 'Mr FooBar', password: 'password' }
    request.post { uri: url, json: json}, (err, res, body) ->
      expect(res.statusCode).toBe(201)
      User.findById(body._id).exec (err, user) ->
        expect(err).toBeNull()
        expect(user).toBeDefined()
        done()
