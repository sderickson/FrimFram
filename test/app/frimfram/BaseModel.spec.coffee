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

class BlandModel extends FrimFram.BaseModel
  idAttribute: '_id'
  @className: 'Bland'
  @schema: 'http://my.site/schemas#bland'
  urlRoot: '/db/bland'

describe 'BaseModel', ->
  
  describe 'dataState', ->
    it 'is "fetching" while the model is being fetched, "saving" while the model is being saved, and "standby" otherwise', ->
      b = new BlandModel({})
      expect(b.dataState).toBe("standby")
      b.fetch()
      expect(b.dataState).toBe("fetching")
      request = jasmine.Ajax.requests.mostRecent()
      request.respondWith({status: 200, responseText: '{}'})
      expect(b.dataState).toBe("standby")
      b.fetch()
      expect(b.dataState).toBe("fetching")
      request = jasmine.Ajax.requests.mostRecent()
      request.respondWith({status: 404, responseText: '{}'})
      expect(b.dataState).toBe("standby")
      
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
    it 'does not save if the data is invalid based on the schema', ->
      b = new BlandModel({number: 'NaN'})
      res = b.save()
      expect(res).toBe(false)
      request = jasmine.Ajax.requests.mostRecent()
      expect(request).toBeUndefined()

  describe 'schema()', ->
    it 'dereferences the class property "schema" if it\'s a string using tv4.getSchema', ->
      b = new BlandModel()
      expect(b.schema().id).toBe('http://my.site/schemas#bland')
