BaseModel = require 'models/BaseModel'
SuperModel = require 'models/SuperModel'
BaseCollection = require 'collections/BaseCollection'

class BlandModel extends BaseModel
  @className: 'Bland'
  @schema: {}
  urlRoot: '/db/bland'

describe 'SuperModel', ->
  s = null
  
  beforeEach -> s = new SuperModel()
  afterEach -> s.destroy()
  
  it 'is finished by default', ->
    expect(s.finished()).toBeTruthy()
      
  it 'tracks how many of its registered resources have loaded', ->
    b1 = new BlandModel()
    b1.fetch()
    b2 = new BlandModel()
    b2.fetch()
    jqxhr = $.ajax('/some/url')
    
    s.registerModel(b1, {value:1})
    s.registerModel(b2, {value:3})
    s.registerJQXHR(jqxhr, {value:4})
    resource = {}
    s.registerCustomResource(resource, {value:2})
    
    requests = jasmine.Ajax.requests.all()
    
    expect(s.progress().value).toBe(0)
    requests[0].response({status: 200, responseText: '{"_id":1}'})
    expect(s.progress().value).toBe(0.1)
    requests[1].response({status: 200, responseText: '{"_id":2}'})
    expect(s.progress().value).toBe(0.4)
    requests[2].response({status: 200, responseText: '{"response":{"groups":[{"type":"nearby","name":"Nearby","items":[{"id":"4bb9fd9f3db7b7138dbd229a","name":"Pivotal Labs","contact":{"twitter":"pivotalboulder"},"location":{"address":"1701 Pearl St.","crossStreet":"at 17th St.","city":"Boulder","state":"CO","lat":40.019461,"lng":-105.273296,"distance":0},"categories":[{"id":"4bf58dd8d48988d124941735","name":"Office","pluralName":"Offices","icon":"https://foursquare.com/img/categories/building/default.png","parents":["Homes, Work, Others"],"primary":true}],"verified":false,"stats":{"checkinsCount":223,"usersCount":62},"hereNow":{"count":0}},{"id":"4af2eccbf964a5203ae921e3","name":"Laughing Goat Café","contact":{},"location":{"address":"1709 Pearl St.","crossStreet":"btw 16th & 17th","city":"Boulder","state":"CO","postalCode":"80302","country":"USA","lat":40.019321,"lng":-105.27311982,"distance":21},"categories":[{"id":"4bf58dd8d48988d1e0931735","name":"Coffee Shop","pluralName":"Coffee Shops","icon":"https://foursquare.com/img/categories/food/coffeeshop.png","parents":["Food"],"primary":true},{"id":"4bf58dd8d48988d1a7941735","name":"College Library","pluralName":"College Libraries","icon":"https://foursquare.com/img/categories/education/default.png","parents":["Colleges & Universities"]}],"verified":false,"stats":{"checkinsCount":1314,"usersCount":517},"hereNow":{"count":0}},{"id":"4ca777a597c8a1cdf7bc7aa5","name":"Ted\'s Montana Grill","contact":{"phone":"3034495546","formattedPhone":"(303) 449-5546","twitter":"TedMontanaGrill"},"location":{"address":"1701 Pearl St.","crossStreet":"17th and Pearl","city":"Boulder","state":"CO","postalCode":"80302","country":"USA","lat":40.019376,"lng":-105.273311,"distance":9},"categories":[{"id":"4bf58dd8d48988d1cc941735","name":"Steakhouse","pluralName":"Steakhouses","icon":"https://foursquare.com/img/categories/food/steakhouse.png","parents":["Food"],"primary":true}],"verified":true,"stats":{"checkinsCount":197,"usersCount":150},"url":"http://www.tedsmontanagrill.com/","hereNow":{"count":0}},{"id":"4d3cac5a8edf3704e894b2a5","name":"Pizzeria Locale","contact":{},"location":{"address":"1730 Pearl St","city":"Boulder","state":"CO","postalCode":"80302","country":"USA","lat":40.0193746,"lng":-105.2726744,"distance":53},"categories":[{"id":"4bf58dd8d48988d1ca941735","name":"Pizza Place","pluralName":"Pizza Places","icon":"https://foursquare.com/img/categories/food/pizza.png","parents":["Food"],"primary":true}],"verified":false,"stats":{"checkinsCount":511,"usersCount":338},"hereNow":{"count":2}},{"id":"4d012cd17c56370462a6b4f0","name":"The Pinyon","contact":{},"location":{"address":"1710 Pearl St.","city":"Boulder","state":"CO","country":"USA","lat":40.019219,"lng":-105.2730563,"distance":33},"categories":[{"id":"4bf58dd8d48988d14e941735","name":"American Restaurant","pluralName":"American Restaurants","icon":"https://foursquare.com/img/categories/food/default.png","parents":["Food"],"primary":true}],"verified":true,"stats":{"checkinsCount":163,"usersCount":98},"hereNow":{"count":1}}]}]}}'})
    expect(s.progress().value).toBe(0.8)
    s.markCustomResourceLoaded(resource)
    expect(s.progress().value).toBe(1)
      
  describe 'collections of stored models, grouped by model type', ->
    it 'stores registered, fetching models once they have loaded', ->
      b = new BlandModel()
      b.fetch()
      s.registerModel(b)
      request = jasmine.Ajax.requests.mostRecent()
      request.response({status: 200, responseText: '{"_id":1, "key":"value"}'})
      expect(s.Bland.models.length).toBe(1)
      expect(s.Bland.find({id:1})).toBeTruthy()
    
    it 'stores models that are already loaded', ->
      b = new BlandModel({"_id":1, "key":"value"})
      s.registerModel(b)
      expect(s.Bland.find({id:1})).toBeTruthy()
    
    it 'stores models that arrive in a registered collection once it loads', ->
      Collection = BaseCollection.extend({url: '/db/bland', model: BlandModel})
      c = new Collection()
      c.fetch()
      s.registerCollection(c)
      request = jasmine.Ajax.requests.mostRecent()
      request.response({status: 200, responseText: '[{"_id":1}]'})
      expect(s.Bland.find({id:1})).toBeTruthy()
      
    it 'stores models in collections that are already loaded', ->
      Collection = BaseCollection.extend({url: '/db/bland', model: BlandModel})
      c = new BaseCollection([{"_id":1}], {loaded: true})
      s.registerCollection(c)
      expect(s.Bland.find({id:1})).toBeTruthy()
      
  describe 'model conflicts', ->
    it 'merges properties from the latter model into the former model', ->
      b1 = new BlandModel({"_id":1, "key1":"value1"})
      b2 = new BlandModel({"_id":1, "key2":"value2"})
      s.registerModel(b1)
      s.registerModel(b2)
      expect(s.Bland.models.length).toBe(1)
      b3 = s.Bland.find({id:1})
      expect(b3).toBe(b1)
      expect(b3.get('key1')).toBe('value1')
      expect(b3.get('key2')).toBe('value2')

    it 'updates the project property in the model receiving merges', ->
      b1 = new BlandModel({"_id":1, "key1":"value1"}, {project: ['key1']})
      b2 = new BlandModel({"_id":1, "key2":"value2"})
      s.registerModel(b1)
      s.registerModel(b2)
      b3 = s.Bland.find({id:1})
      expect(b3.project.length).toBe(2)
