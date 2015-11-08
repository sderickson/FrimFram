describe 'Collection', ->
  describe 'dataState', ->
    it 'is "fetching" while the collection is being fetched, "standby" otherwise', ->
      Collection = FrimFram.Collection.extend({
        url: '/db/thingies'
      })
      collection = new Collection()
      expect(collection.dataState).toBe("standby")
      collection.fetch()
      expect(collection.dataState).toBe("fetching")
      request = jasmine.Ajax.requests.mostRecent()
      request.respondWith({status: 200, responseText: '[]'})
      expect(collection.dataState).toBe("standby")
      collection.fetch()
      expect(collection.dataState).toBe("fetching")
      request = jasmine.Ajax.requests.mostRecent()
      request.respondWith({status: 404, responseText: '{}'})
      expect(collection.dataState).toBe("standby")

    it 'is set before any given success or error callback is called', ->
      Collection = FrimFram.Collection.extend({
        url: '/db/thingies'
      })
      collection = new Collection()
      calls = 0
      collection.fetch({
        success: ->
          calls += 1
          expect(collection.dataState).toBe("standby")
        })
      jasmine.Ajax.requests.mostRecent().respondWith({status: 200, responseText: '[]'})
      collection.fetch({
        error: ->
          calls += 1
          expect(collection.dataState).toBe("standby")
      })
      jasmine.Ajax.requests.mostRecent().respondWith({status: 404, responseText: '[]'})
      expect(calls).toBe(2)

  describe 'constructor(models, options)', ->
    it 'can be given defaultFetchData as an option, which will be folded into all fetch operations', ->
      Collection = FrimFram.Collection.extend({
        url: '/db/thingies'
      })
      collection = new Collection(null, {defaultFetchData: {foo: 'bar'}})
      collection.fetch()
      request = jasmine.Ajax.requests.mostRecent()
      window.s = request.url
      expect(_(request.url).contains('foo=bar')).toBe(true)

      collection = new Collection(null, {defaultFetchData: {foo: 'bar'}})
      collection.fetch({data: {bar: 'foo'}})
      request = jasmine.Ajax.requests.mostRecent()
      expect(_(request.url).contains('foo=bar')).toBe(true)
      expect(_(request.url).contains('bar=foo')).toBe(true)

      collection = new Collection(null, {defaultFetchData: {foo: 'bar'}})
      collection.fetch({data: {foo: 'BAR'}})
      request = jasmine.Ajax.requests.mostRecent()
      expect(_(request.url).contains('foo=BAR')).toBe(true)

  describe 'fetch(options)', ->
    it 'calls options.success and options.error after dataState is back to "standby"', ->
      count = 0
      callback = (c) ->
        expect(c.dataState).toBe('standby')
        count += 1

      Collection = FrimFram.Collection.extend({
        url: '/db/thingies'
      })
      c = new Collection()

      expect(c.dataState).toBe('standby')

      c.fetch({ success: callback })
      expect(c.dataState).toBe('fetching')
      request = jasmine.Ajax.requests.mostRecent()
      request.respondWith({status: 200, responseText: '{}'})

      c.fetch({ complete: callback })
      expect(c.dataState).toBe('fetching')
      request = jasmine.Ajax.requests.mostRecent()
      request.respondWith({status: 200, responseText: '{}'})

      c.fetch({ error: callback })
      expect(c.dataState).toBe('fetching')
      request = jasmine.Ajax.requests.mostRecent()
      request.respondWith({status: 404, responseText: '{}'})

      expect(count).toBe(3)