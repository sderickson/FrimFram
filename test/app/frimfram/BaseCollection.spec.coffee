describe 'BaseCollection', ->
  describe 'dataState', ->
    it 'is "fetching" while the collection is being fetched, "standby" otherwise', ->
      Collection = FrimFram.BaseCollection.extend({
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

  describe 'constructor(models, options)', ->
    it 'can be given defaultFetchData as an option, which will be folded into all fetch operations', ->
      Collection = FrimFram.BaseCollection.extend({
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
