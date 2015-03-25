describe 'BaseView', ->
  it 'listens to shortcuts upon construction', ->
    View = FrimFram.BaseView.extend({
      shortcuts:
        'enter': _.noop
    })
    spyOn(window, 'key')
    new View()
    expect(key).toHaveBeenCalled()

    
  describe '.render()', ->
    it 'destroys and resets subviews', ->
      View = FrimFram.BaseView.extend({
        template: '<div id="subview"></div>'
      })
      view = new View()
      view.render()
      Subview = FrimFram.BaseView.extend({
        id: 'subview'
      })
      subview = new Subview()
      
      view.insertSubview(subview)
      expect(subview.destroyed).toBeFalsy()
      expect(_.values(view.subviews)[0]).toBe(subview)
      
      view.render()
      expect(subview.destroyed).toBeTruthy()
      expect(_.values(view.subviews).length).toBe(0)
    
    it 'inserts the template value into $el', ->
      html = '<p>Value</p>'
      View = FrimFram.BaseView.extend({
        template: html
      })
      view = new View()
      view.render()
      expect(view.$el.html()).toBe(html)
    
    it 'it calls onRender at the end', ->
      view = new FrimFram.BaseView()
      spyOn(view, 'onRender')
      view.render()
      expect(view.onRender).toHaveBeenCalled()
      
    
  describe '.renderSelectors(selectors...)', ->
    it 'rerenders selectors passed in as arguments', ->
      View = FrimFram.BaseView.extend({
        template: (c) -> "<div><div id='foo'>#{c.foo}</div><div id='bar'>#{c.bar}</div></div>"
        getContext: -> @initContext(['foo', 'bar'])
      })
      view = new View()
      view.foo = 1
      view.bar = 1
      view.render()
      expect(view.$el.find('#foo').text()).toBe('1')
      expect(view.$el.find('#bar').text()).toBe('1')
      view.foo = 2
      view.bar = 2
      view.renderSelectors('#foo')
      expect(view.$el.find('#foo').text()).toBe('2')
      expect(view.$el.find('#bar').text()).toBe('1')
    
  describe '.initContext(pickPredicate)', ->
    it 'picks passed in properties from the view instance', ->
      view = new FrimFram.BaseView()
      view.foo = 1
      view.bar = 2
      expect(view.initContext(['foo']).foo).toBe(1)
      expect(view.initContext(['bar']).bar).toBe(2)
      expect(view.initContext(['foo']).bar).toBeUndefined()
    
    it 'includes pathname', ->
      view = new FrimFram.BaseView()
      expect(view.initContext().pathname).toBe(document.location.pathname)
          
    it 'includes globals set by @setGlobals()', ->
      view = new FrimFram.BaseView()
      window.someLib = {}
      FrimFram.BaseView.setGlobals(['someLib'])
      expect(view.initContext().someLib).toBe(window.someLib)
    
    
  describe '.getContext()', ->
    it 'proxies to .initContext() by default', ->
      view = new FrimFram.BaseView()
      spyOn(view, 'initContext')
      view.getContext()
      expect(view.initContext).toHaveBeenCalled()
    
    it 'is intended to be overridden', -> expect(true).toBe(true)


  describe '.onRender()', ->
    it 'is intended to be overridden', -> expect(true).toBe(true)


  describe '.onInsert()', ->
    it 'is intended to be overridden', -> expect(true).toBe(true)


  describe '.listenToShortcuts(recurse)', ->
    it 'recursively calls subviews when the "recurse" is true', ->
      View = FrimFram.BaseView.extend({
        template: '<div id="subview"></div>'
      })
      view = new View()
      view.render()
      Subview = FrimFram.BaseView.extend({
        id: 'subview'
      })
      subview = new Subview()
      view.insertSubview(subview)
      
      spyOn(subview, 'listenToShortcuts')
      view.listenToShortcuts(true)
      expect(subview.listenToShortcuts).toHaveBeenCalled()
    
    
  describe '.stopListeningToShortcuts(recurse)', ->
    it 'recursively calls subviews when the first argument is true', ->
      View = FrimFram.BaseView.extend({
        template: '<div id="subview"></div>'
      })
      view = new View()
      view.render()
      Subview = FrimFram.BaseView.extend({
        id: 'subview'
      })
      subview = new Subview()
      view.insertSubview(subview)

      spyOn(subview, 'stopListeningToShortcuts')
      view.stopListeningToShortcuts(true)
      expect(subview.stopListeningToShortcuts).toHaveBeenCalled()
    
  
  describe '.insertSubview(view, elToReplace)', ->
    it 'inserts "view" into $el based on the view\'s id property', ->
      View = FrimFram.BaseView.extend({
        template: '<div><div id="subview"></div></div>'
      })
      view = new View()
      view.render()
      Subview = FrimFram.BaseView.extend({
        id: 'subview'
      })
      subview = new Subview()
      view.insertSubview(subview)
      expect(view.$el.find('#subview')[0]).toBe(subview.el)
      
    
    it 'calls the subview\'s render and onInsert methods', ->
      View = FrimFram.BaseView.extend({
        template: '<div><div id="subview"></div></div>'
      })
      view = new View()
      view.render()
      Subview = FrimFram.BaseView.extend({
        id: 'subview'
      })
      subview = new Subview()
      spyOn(subview, 'render')
      spyOn(subview, 'onInsert')
      view.insertSubview(subview)
      expect(subview.render).toHaveBeenCalled()
      expect(subview.onInsert).toHaveBeenCalled()


  describe '.registerSubview()', ->
    it 'adds the given view to the subviews object', ->
      View = FrimFram.BaseView.extend({
        template: '<div><div id="subview"></div></div>'
      })
      view = new View()
      view.render()
      Subview = FrimFram.BaseView.extend({
        id: 'subview'
      })
      subview = new Subview()
      view.insertSubview(subview)
      expect(_.values(view.subviews)[0]).toBe(subview)
    
    
  describe '.removeSubView()', ->
    it 'removes and destroys a given view', ->
      View = FrimFram.BaseView.extend({
        template: '<div><div id="subview"></div></div>'
      })
      view = new View()
      view.render()
      Subview = FrimFram.BaseView.extend({
        id: 'subview'
        template: '<div>Test</div>'
      })
      subview = new Subview()
      view.insertSubview(subview)
      expect(view.$el.find('#subview').length).toBe(1)
      view.removeSubview(subview)
      expect(view.$el.find('#subview').length).toBe(0)
      expect(subview.destroyed).toBeTruthy()
    
    
  describe '@getQueryParam(param) and .getQueryParam(param)', ->
    it 'parses a given parameter out of the query string', ->
      spyOn(FrimFram.BaseView, 'getQueryString').and.returnValue('test=ing&what=wut')
      expect(FrimFram.BaseView.getQueryParam('test')).toBe('ing')
      expect(FrimFram.BaseView.getQueryParam('what')).toBe('wut')
    
  
  describe '.destroy()', ->
    it 'calls Backbone.View.remove', ->
      view = new FrimFram.BaseView()
      spyOn(view, 'remove')
      spy = view.remove
      view.destroy()
      expect(spy).toHaveBeenCalled()
    
    it 'stops listening to shortcuts', ->
      view = new FrimFram.BaseView()
      spyOn(view, 'stopListeningToShortcuts')
      spy = view.stopListeningToShortcuts
      view.destroy()
      expect(spy).toHaveBeenCalled()
    
    it 'destroys all subviews', ->
      View = FrimFram.BaseView.extend({
        template: '<div><div id="subview"></div></div>'
      })
      view = new View()
      view.render()
      Subview = FrimFram.BaseView.extend({
        id: 'subview'
        template: '<div>Test</div>'
      })
      subview = new Subview()
      view.insertSubview(subview)
      view.destroy()
      expect(subview.destroyed).toBeTruthy()      

    it 'clears all properties from the object, except for "destroyed" and "destroy"', ->
      view = new FrimFram.BaseView()
      view.destroy()
      expect(_.isEqual(_.keys(view), ['destroyed', 'destroy'])).toBe(true) 