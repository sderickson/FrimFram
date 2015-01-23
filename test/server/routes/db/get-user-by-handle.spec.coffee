main = require '../../main'
request = require 'request'
mockgoose = require 'mockgoose'
utils = rootRequire 'test/server/utils'
url = utils.makeURL('/db/user')

User = rootRequire 'server/models/User'

describe 'GET /db/user/:handle', ->
  
  test = {}

  beforeEach (done) -> main.onReady ->
    json = { email: 'something@gmail.com', name: 'Mr FooBar', password: 'password' }
    request.post { uri: url, json: json}, (err, res, body) ->
      expect(res.statusCode).toBe(201)
      test.user = body
      done()
      
  afterEach ->
    mockgoose.reset()

  it 'returns 200 for a user that exists', (done) ->
    request.get { uri: utils.makeURL("/db/user/#{test.user._id}") }, (err, res, body) ->
      expect(res.statusCode).toBe(200)
      done()
    
  it 'returns 404 for a user that does not exist', (done) ->
    request.get { uri: utils.makeURL('/db/user/012345678901234567890123') }, (err, res, body) ->
      expect(res.statusCode).toBe(404)
      done()
      
  it 'can do lookups by slugs', (done) ->
    request.get { uri: utils.makeURL("/db/user/#{test.user.slug}") }, (err, res, body) ->
      expect(res.statusCode).toBe(200)
      done()