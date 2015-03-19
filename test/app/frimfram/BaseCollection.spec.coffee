class BlandModel extends FrimFram.BaseModel
  @className: 'Bland'
  @schema: {}
  urlRoot: '/db/bland'

describe 'BaseCollection', ->
  xit 'should properly process raw data handed into it', ->
    Collection = FrimFram.BaseCollection.extend({url: '/db/bland', model: BlandModel})
    c = new BaseCollection([{_id:'1'}])
    b = new BlandModel({_id:'1'})
    expect(b.id).toBeTruthy()

    # I expect it to be this way but it isn't. What's going on?
    expect(c.models[0].id).toBeTruthy()  