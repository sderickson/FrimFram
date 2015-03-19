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
      request.response({status: 200, responseText: '[]'})
      expect(collection.dataState).toBe("standby")
      collection.fetch()
      expect(collection.dataState).toBe("fetching")
      request = jasmine.Ajax.requests.mostRecent()
      request.response({status: 404, responseText: '{}'})
      expect(collection.dataState).toBe("standby")
