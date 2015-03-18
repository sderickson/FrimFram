BaseModel = require 'models/BaseModel'

tv4.addSchema({
  id: 'http://my.site/schemas#bland'
  type: 'object'
  additionalProperties: false
  default: { number: 1 }
  properties:
    number: {type: 'number'}
    object: {type: 'object'}
    string: {type: 'string'}
    _id: {type: 'string'}
})

class BlandModel extends BaseModel
  idAttribute: '_id'
  @className: 'Bland'
  @schema: 'http://my.site/schemas#bland'
  urlRoot: '/db/bland'

describe 'BaseModel', ->
  
  describe 'fetching', ->
    it 'is true while the model is being fetched from the server', ->
      b = new BlandModel({})
      expect(b.fetching).toBe(false)
      b.fetch()
      expect(b.fetching).toBe(true)
      request = jasmine.Ajax.requests.mostRecent()
      request.response({status: 200, responseText: '{}'})
      expect(b.fetching).toBe(false)
      b.fetch()
      expect(b.fetching).toBe(true)
      request = jasmine.Ajax.requests.mostRecent()
      request.response({status: 404, responseText: '{}'})
      expect(b.fetching).toBe(false)
      
    it 'is false while the model is being saved to the server', ->
      b = new BlandModel({})
      b.save()
      expect(b.fetching).toBe(false)
      
  describe 'saving', ->
    it 'is true while the model is being saved to the server', ->
      b = new BlandModel({})
      expect(b.saving).toBe(false)
      b.save()
      expect(b.saving).toBe(true)
      request = jasmine.Ajax.requests.mostRecent()
      request.response({status: 200, responseText: '{}'})
      expect(b.saving).toBe(false)
      b.save()
      expect(b.saving).toBe(true)
      request = jasmine.Ajax.requests.mostRecent()
      request.response({status: 401, responseText: '{}'})
      expect(b.saving).toBe(false)
      
    it 'is false while the model is being fetched from the server', ->
      b = new BlandModel({})
      b.fetch()
      expect(b.saving).toBe(false)

  describe 'setProjection()', ->
    it 'takes an array of properties to project and adds them as a query parameter', ->
      b = new BlandModel({})
      b.setProjection ['number', 'object']
      b.fetch()
      request = jasmine.Ajax.requests.mostRecent()
      expect(decodeURIComponent(request.url).indexOf('project=number,object')).toBeGreaterThan(-1)

  describe 'set()', ->
    it 'throws an error when you try to set properties while saving', ->
      b = new BlandModel({})
      b.save()
      expect(-> b.set('a', 1)).toThrow()

    it 'throws an error when you try to set properties while fetching', ->
      b = new BlandModel({})
      b.fetch()
      expect(-> b.set('a', 1)).toThrow()

  describe 'save()', ->
    it 'saves to db/<urlRoot>', ->
      b = new BlandModel({})
      res = b.save()
      request = jasmine.Ajax.requests.mostRecent()
      expect(res).toBeDefined()
      expect(request.url).toBe(b.urlRoot)
      expect(request.method).toBe('POST')

    it 'does not save if the data is invalid based on the schema', ->
      b = new BlandModel({number: 'NaN'})
      res = b.save()
      expect(res).toBe(false)
      request = jasmine.Ajax.requests.mostRecent()
      expect(request).toBeUndefined()

    it 'uses PUT when _id is included', ->
      b = new BlandModel({_id: 'test'})
      b.save()
      request = jasmine.Ajax.requests.mostRecent()
      expect(request.method).toBe('PUT')
      
  describe 'schema()', ->
    it 'dereferences the class property "schema" if it\'s a string using tv4.getSchema', ->
      b = new BlandModel()
      expect(b.schema().id).toBe('http://my.site/schemas#bland')

  describe 'fetch()', ->
    it 'straight up fetches from the url root if no other guidance is given', ->
      b = new BlandModel({})
      b.fetch()
      request = jasmine.Ajax.requests.mostRecent()
      expect(request.url).toBe('/db/bland')

    it 'can take data parameters to include in the GET request', ->
      b = new BlandModel({})
      b.fetch({data: {'slug':'mayo'}})
      request = jasmine.Ajax.requests.mostRecent()
      expect(request.url).toBe('/db/bland?slug=mayo')
      
    it 'will use a url set directly to the instance', ->
      b = new BlandModel({})
      b.url = '/db/user/1/most-recent-bland'
      b.fetch()
      request = jasmine.Ajax.requests.mostRecent()
      expect(request.url).toBe('/db/user/1/most-recent-bland')
      
    it 'will use an id passed into the constructor', ->
      b = new BlandModel({_id: '1'})
      b.fetch()
      request = jasmine.Ajax.requests.mostRecent()
      expect(request.url).toBe('/db/bland/1')
      
    it 'will set its url value to a direct value on success', ->
      b = new BlandModel({})
      b.fetch()
      request = jasmine.Ajax.requests.mostRecent()
      request.response({status: 200, responseText: '{"_id":1}'})
      expect(b.url).toBe('/db/bland/1')
