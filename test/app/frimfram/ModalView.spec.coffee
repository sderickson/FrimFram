describe 'Modal', ->
  
  afterEach ->
    FrimFram.Modal.visibleModal?.hide(true)
  
  it 'proxies Bootstrap Events through itself as Bootstrap Events', ->
    modal = new FrimFram.Modal()
    
    # create a listener that listens to modal callbacks, spy those callbacks
    callbacks = ['show', 'shown', 'hide', 'hidden']
    listener = _.extend({}, Backbone.Events)
    for callback in callbacks
      listener[callback] = ->
      spyOn(listener, callback)
      listener.listenTo(modal, callback, listener[callback])
    
    # trigger the callbacks
    modal.show(true)
    modal.hide(true)
    
    # did the callbacks get called?
    for callback in callbacks
      expect(listener[callback]).toHaveBeenCalled()

  describe '.show(fast)', ->
    it 'closes currently visible modal', ->
      modal1 = new FrimFram.Modal()
      modal2 = new FrimFram.Modal()
      modal1.show()
      spyOn(modal1, 'hide').and.callThrough()
      spy = modal1.hide
      modal2.show()
      expect(spy).toHaveBeenCalled()
    
    it 'sets Modal.visibleModal to itself', ->
      modal = new FrimFram.Modal()
      expect(FrimFram.Modal.visibleModal).toBeFalsy()
      modal.show()
      expect(FrimFram.Modal.visibleModal).toBe(modal)
    
    it 'puts the view\'s element into the body tag', ->
      modal = new FrimFram.Modal()
      expect(FrimFram.Modal.visibleModal).toBeFalsy()
      modal.show()
      expect($('.modal')[0]).toBe(modal.el)

    it 'shows itself fast if the first argument is true', (done) ->
      modal = new FrimFram.Modal()
      spy = jasmine.createSpy()
      modal.once 'shown', spy
      modal.show(true)
      expect(spy).toHaveBeenCalled()

      modal = new FrimFram.Modal()
      modal.template = '''<div class="modal-dialog"></div>'''
      modal.show()
      modal.once 'shown', -> done()
    
      
  describe '.hide(fast)', ->
    it 'clears Modal.visibleModal', ->
      modal = new FrimFram.Modal()
      modal.show(true)
      expect(FrimFram.Modal.visibleModal).toBeTruthy()
      modal.hide(true)
      expect(FrimFram.Modal.visibleModal).toBeFalsy()
    
    it 'destroys itself at the end of the hiding process', ->
      modal = new FrimFram.Modal()
      modal.show(true)
      modal.hide(true)
      expect(modal.destroyed).toBeTruthy()
    
    it 'hides itself fast if the first argument is true', ->
      modal = new FrimFram.Modal()
      spy = jasmine.createSpy()
      modal.once 'hidden', spy
      modal.show(true)
      modal.hide(true)
      expect(spy).toHaveBeenCalled()

      modal = new FrimFram.Modal()
      modal.template = '''<div class="modal-dialog"></div>'''
      modal.show(true)
      modal.hide()
      modal.once 'hidden', -> done()
      
      
  describe '.destroyOnHidden', ->
    it 'can be used to keep a modal from destroying itself on hidden', ->
      Modal = FrimFram.Modal.extend({
        destroyOnHidden: false
      })
      modal = new Modal()
      modal.show(true)
      modal.hide(true)
      expect(modal.destroyed).toBeFalsy()