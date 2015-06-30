describe 'View', ->
  it 'listens to shortcuts upon construction', ->
    View = FrimFram.View.extend({
      shortcuts:
        'enter': _.noop
    })
    spyOn(window, 'key')
    new View()
    expect(key).toHaveBeenCalled()


  describe '.constructor(options, ...)', ->
    it 'passes options and any additional arguments on to initialize', ->
      spy = jasmine.createSpy()
      View = FrimFram.View.extend({
        initialize: spy
      })
      view = new View(1, 2, 3)
      expect(spy).toHaveBeenCalledWith(1, 2, 3)


  describe '.render()', ->
    it 'destroys and resets subviews', ->
      View = FrimFram.View.extend({
        template: '<div id="subview"></div>'
      })
      view = new View()
      view.render()
      Subview = FrimFram.View.extend({
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
      View = FrimFram.View.extend({
        template: html
      })
      view = new View()
      view.render()
      expect(view.$el.html()).toBe(html)

    it 'it calls onRender at the end', ->
      view = new FrimFram.View()
      spyOn(view, 'onRender')
      view.render()
      expect(view.onRender).toHaveBeenCalled()


  describe '.renderSelectors(selectors...)', ->
    it 'rerenders selectors passed in as arguments', ->
      View = FrimFram.View.extend({
        template: (c) -> "<div id='foo'>#{c.foo}</div><div id='bar'>#{c.bar}</div>"
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
      view = new FrimFram.View()
      view.foo = 1
      view.bar = 2
      expect(view.initContext(['foo']).foo).toBe(1)
      expect(view.initContext(['bar']).bar).toBe(2)
      expect(view.initContext(['foo']).bar).toBeUndefined()

    it 'includes pathname', ->
      view = new FrimFram.View()
      expect(view.initContext().pathname).toBe(document.location.pathname)

    it 'includes globals added by @extendGlobalContext(context)', ->
      view = new FrimFram.View()
      someLib = {}
      FrimFram.View.extendGlobalContext({'someLib':someLib})
      expect(view.initContext().someLib).toBe(someLib)


  describe '.getContext()', ->
    it 'proxies to .initContext() by default', ->
      view = new FrimFram.View()
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
      View = FrimFram.View.extend({
        template: '<div id="subview"></div>'
      })
      view = new View()
      view.render()
      Subview = FrimFram.View.extend({
        id: 'subview'
      })
      subview = new Subview()
      view.insertSubview(subview)

      spyOn(subview, 'listenToShortcuts')
      view.listenToShortcuts(true)
      expect(subview.listenToShortcuts).toHaveBeenCalled()


  describe '.stopListeningToShortcuts(recurse)', ->
    it 'recursively calls subviews when the first argument is true', ->
      View = FrimFram.View.extend({
        template: '<div id="subview"></div>'
      })
      view = new View()
      view.render()
      Subview = FrimFram.View.extend({
        id: 'subview'
      })
      subview = new Subview()
      view.insertSubview(subview)

      spyOn(subview, 'stopListeningToShortcuts')
      view.stopListeningToShortcuts(true)
      expect(subview.stopListeningToShortcuts).toHaveBeenCalled()


  describe '.insertSubview(view, elToReplace)', ->
    it 'inserts "view" into $el based on the view\'s id property', ->
      View = FrimFram.View.extend({
        template: '<div><div id="subview"></div></div>'
      })
      view = new View()
      view.render()
      Subview = FrimFram.View.extend({
        id: 'subview'
      })
      subview = new Subview()
      view.insertSubview(subview)
      expect(view.$el.find('#subview')[0]).toBe(subview.el)


    it 'calls the subview\'s render and onInsert methods', ->
      View = FrimFram.View.extend({
        template: '<div><div id="subview"></div></div>'
      })
      view = new View()
      view.render()
      Subview = FrimFram.View.extend({
        id: 'subview'
      })
      subview = new Subview()
      spyOn(subview, 'render')
      spyOn(subview, 'onInsert')
      view.insertSubview(subview)
      expect(subview.render).toHaveBeenCalled()
      expect(subview.onInsert).toHaveBeenCalled()

    it 'replaces existing subviews for a given id', ->
      View = FrimFram.View.extend({ template: '<div id="subview"></div>' })
      view = new View()
      view.render()
      Subview = FrimFram.View.extend({ id: 'subview' })
      subview1 = new Subview()
      subview2 = new Subview()
      view.insertSubview(subview1)
      view.insertSubview(subview2)
      expect(subview1.destroyed).toBeTruthy()
      expect(subview2.destroyed).toBeFalsy()
      expect(view.$el.find('#subview')[0]).toBe(subview2.el)


  describe '.registerSubview()', ->
    it 'adds the given view to the subviews object', ->
      View = FrimFram.View.extend({
        template: '<div><div id="subview"></div></div>'
      })
      view = new View()
      view.render()
      Subview = FrimFram.View.extend({
        id: 'subview'
      })
      subview = new Subview()
      view.insertSubview(subview)
      expect(_.values(view.subviews)[0]).toBe(subview)


  describe '.removeSubview()', ->
    it 'removes and destroys a given view', ->
      View = FrimFram.View.extend({
        template: '<div><div id="subview"></div></div>'
      })
      view = new View()
      view.render()
      Subview = FrimFram.View.extend({
        id: 'subview'
        template: '<div>Test</div>'
      })
      subview = new Subview()
      view.insertSubview(subview)
      expect(view.$el.find('#subview').text()).toBeTruthy()
      view.removeSubview(subview)
      expect(view.$el.find('#subview').text()).toBeFalsy()
      expect(subview.destroyed).toBeTruthy()

    it 'leaves a clone of the original el behind so insertSubview still works', ->
      View = FrimFram.View.extend({
        template: '<div><div id="subview"></div></div>'
      })
      view = new View()
      view.render()
      Subview = FrimFram.View.extend({
        id: 'subview'
        template: '<div>Test</div>'
      })
      subview = new Subview()
      expect(view.$el.find('#subview').text()).toBeFalsy()
      view.insertSubview(subview)
      expect(view.$el.find('#subview').text()).toBeTruthy()
      view.removeSubview(subview)
      expect(view.$el.find('#subview').text()).toBeFalsy()

      subview = new Subview()
      view.insertSubview(subview)
      expect(view.$el.find('#subview').text()).toBeTruthy()

  describe '@getQueryParam(param) and .getQueryParam(param)', ->
    it 'parses a given parameter out of the query string', ->
      qString = 'test=ing&what=wut&encodings=%23%5E%40%24%2B%25&spaced=Cool+Story%2C+Bro!'
      spyOn(FrimFram.View, 'getQueryString').and.returnValue(qString)
      expect(FrimFram.View.getQueryParam('test')).toBe('ing')
      expect(FrimFram.View.getQueryParam('what')).toBe('wut')
      expect(FrimFram.View.getQueryParam('encodings')).toBe('#^@$+%')
      expect(FrimFram.View.getQueryParam('spaced')).toBe('Cool Story, Bro!')

  describe '.destroy()', ->
    it 'calls Backbone.View.remove', ->
      view = new FrimFram.View()
      spyOn(view, 'remove')
      spy = view.remove
      view.destroy()
      expect(spy).toHaveBeenCalled()

    it 'stops listening to shortcuts', ->
      view = new FrimFram.View()
      spyOn(view, 'stopListeningToShortcuts')
      spy = view.stopListeningToShortcuts
      view.destroy()
      expect(spy).toHaveBeenCalled()

    it 'destroys all subviews', ->
      View = FrimFram.View.extend({
        template: '<div><div id="subview"></div></div>'
      })
      view = new View()
      view.render()
      Subview = FrimFram.View.extend({
        id: 'subview'
        template: '<div>Test</div>'
      })
      subview = new Subview()
      view.insertSubview(subview)
      view.destroy()
      expect(subview.destroyed).toBeTruthy()

    it 'clears all properties from the object, except for "destroyed" and "destroy"', ->
      view = new FrimFram.View()
      view.destroy()
      expect(_.isEqual(_.keys(view), ['destroyed', 'destroy'])).toBe(true)