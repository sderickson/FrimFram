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

class BlandModel extends FrimFram.Model
  idAttribute: '_id'
  initialize: _.noop
  @className: 'Bland'
  @schema: 'http://my.site/schemas#bland'
  urlRoot: '/db/bland'

describe 'Model', ->

  describe '.state', ->
    it 'is "fetching" while the model is being fetched, "saving" while the model is being saved, and "standby" otherwise', ->
      b = new BlandModel({})
      expect(b.state).toBe("standby")
      b.fetch()
      expect(b.state).toBe("fetching")
      request = jasmine.Ajax.requests.mostRecent()
      request.respondWith({status: 200, responseText: '{}'})
      expect(b.state).toBe("standby")
      b.fetch()
      expect(b.state).toBe("fetching")
      request = jasmine.Ajax.requests.mostRecent()
      request.respondWith({status: 404, responseText: '{}'})
      expect(b.state).toBe("standby")

  describe '.get(attribute)', ->
    it 'can accept nested properties', ->
      m = new BlandModel({prop: 1, nested: {a: 1, b: 2}})
      expect(m.get('nested.a')).toBe(1)
      expect(m.get('nested.b')).toBe(2)
      expect(m.get('nested.3')).toBeUndefined()

  describe '.set(attributes, options)', ->
    it 'throws an error when you try to set properties while saving', ->
      b = new BlandModel({})
      b.save()
      expect(-> b.set('a', 1)).toThrow()

    it 'throws an error when you try to set properties while fetching', ->
      b = new BlandModel({})
      b.fetch()
      expect(-> b.set('a', 1)).toThrow()

    it 'does not throw an error when set is called through save', ->
      b = new BlandModel({})
      expect(-> b.save({1:2})).not.toThrow()

    it 'can accept nested properties', ->
      m = new BlandModel({prop: 1, nested: {a: 1, b: 2}})
      m.set('nested.a', 'one')
      expect(m.get('nested').a).toBe('one')
      m.set({'nested.b': 'two'})
      expect(m.get('nested').b).toBe('two')
      m.set('whatev.a', 'somethin')
      expect(JSON.stringify(m.attributes)).toBe(JSON.stringify({"prop":1,"nested":{"a":"one","b":"two"}}))

  describe 'save(attributes, options)', ->
    it 'does not save if the data is invalid based on the schema', ->
      b = new BlandModel({number: 'NaN'})
      res = b.save()
      expect(res).toBe(false)
      request = jasmine.Ajax.requests.mostRecent()
      expect(request).toBeUndefined()

    it 'calls options.success and options.error after state is back to "standby"', ->
      count = 0
      callback = (model) ->
        expect(model.state).toBe('standby')
        count += 1

      b = new BlandModel({_id:'1'})
      expect(b.state).toBe('standby')

      b.save(null, { success: callback })
      expect(b.state).toBe('saving')
      request = jasmine.Ajax.requests.mostRecent()
      request.respondWith({status: 200, responseText: '{}'})

      b.save(null, { complete: callback })
      expect(b.state).toBe('saving')
      request = jasmine.Ajax.requests.mostRecent()
      request.respondWith({status: 200, responseText: '{}'})

      b.save(null, { error: callback })
      expect(b.state).toBe('saving')
      request = jasmine.Ajax.requests.mostRecent()
      request.respondWith({status: 404, responseText: '{}'})

      expect(count).toBe(3)

  describe 'fetch(options)', ->
    it 'calls options.success and options.error after state is back to "standby"', ->
      count = 0
      callback = (model) ->
        expect(model.state).toBe('standby')
        count += 1

      b = new BlandModel({_id:1})
      expect(b.state).toBe('standby')

      b.fetch({ success: callback })
      expect(b.state).toBe('fetching')
      request = jasmine.Ajax.requests.mostRecent()
      request.respondWith({status: 200, responseText: '{}'})

      b.fetch({ complete: callback })
      expect(b.state).toBe('fetching')
      request = jasmine.Ajax.requests.mostRecent()
      request.respondWith({status: 200, responseText: '{}'})

      b.fetch({ error: callback })
      expect(b.state).toBe('fetching')
      request = jasmine.Ajax.requests.mostRecent()
      request.respondWith({status: 404, responseText: '{}'})

      expect(count).toBe(3)

  describe 'schema()', ->
    it 'dereferences the class property "schema" if it\'s a string using tv4.getSchema', ->
      b = new BlandModel()
      expect(b.schema().id).toBe('http://my.site/schemas#bland')

  describe 'created()', ->
    it 'gets the document creation date from the MongoDB id', ->
      b = new BlandModel({_id:'55529729ce2868a7fd8d0bb3'})
      expect(b.created().getTime()).toBeCloseTo(1431476009000)