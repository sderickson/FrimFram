describe 'FrimFram.onAjaxError()', ->


describe 'FrimFram.onModelError()', ->
  it 'shows an error alert when set as the "error" callback for Backbone Models and Collections', ->
    Model = FrimFram.BaseModel.extend({ urlRoot: 'http://someplace.com/api/doodad' })
    model = new Model()
    model.fetch({ error: FrimFram.onModelError })
    request = jasmine.Ajax.requests.mostRecent()
    request.respondWith({
      status: 404
      responseText: JSON.stringify({1:2})
    })
    alert = $('body > .alert')
    expect(alert.length).toBe(1)
    alert.remove()
    