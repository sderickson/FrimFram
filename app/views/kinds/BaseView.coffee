visibleModal = null
waitingModal = null

class BaseView extends Backbone.View
  
  template: -> ''
  shortcuts: {}


  #- Setup

  constructor: (options) ->
    @events = @superMerge(@, 'events')
    @subviews = {}
    @listenToShortcuts()
    super options
    
    
  #- Rendering functions, callbacks
    
  render: ->
    # reset subviews
    view.destroy() for id, view of @subviews
    @subviews = {}
    
    # render to element
    html = @getTemplateResult()
    @$el.html html

    @afterRender()
    @
    
  renderSelectors: (selectors...) ->
    newTemplate = $(@getTemplateResult())

    for selector in selectors
      @$el.find(selector).replaceWith(newTemplate.find(selector))

    @delegateEvents()

  getTemplateResult: ->
    if _.isString(@template)
      return @template
    else
      return @template(@getContext())

  afterRender: ->

  getContext: (pick) ->
    context = {}
    context.pathname = document.location.pathname  # ex. '/play/level'
    context.moment = moment
    context = _.extend context, _.pick(@, pick) if pick
    context

  afterInsert: ->


  #- Modals

  openModalView: (modalView, softly=false) ->
    return if waitingModal # can only have one waiting at once
    if visibleModal
      waitingModal = modalView
      return if softly
      return visibleModal.hide() if visibleModal.$el.is(':visible') # close, then this will get called again
      return @modalClosed(visibleModal) # was closed, but modalClosed was not called somehow
    modalView.render()
    $('#modal-wrapper').empty().append modalView.el
    modalView.afterInsert()
    visibleModal = modalView
    modalOptions = {show: true, backdrop: if modalView.closesOnClickOutside then true else 'static'}
    $('#modal-wrapper .modal').modal(modalOptions).on 'hidden.bs.modal', @modalClosed
    @getRootView().stopListeningToShortcuts(true)

  modalClosed: =>
    visibleModal.destroy()
    visibleModal = null
    #$('#modal-wrapper .modal').off 'hidden.bs.modal', @modalClosed
    if waitingModal
      wm = waitingModal
      waitingModal = null
      @openModalView(wm)
    else
      @getRootView().listenToShortcuts(true)

      
  #- Shortcuts

  listenToShortcuts: (recurse) ->
    for shortcut, func of @shortcuts
      func = @normalizeFunc(func)
      key(shortcut, @scope, _.bind(func, @))
    if recurse
      for viewID, view of @subviews
        view.listenToShortcuts()

  stopListeningToShortcuts: (recurse) ->
    key.deleteScope(@scope)
    if recurse
      for viewID, view of @subviews
        view.stopListeningToShortcuts()

        
  #- Subviews

  insertSubView: (view, elToReplace=null) ->
    # used to insert views with ids
    key = @makeSubViewKey(view)
    @subviews[key].destroy() if key of @subviews
    elToReplace ?= @$el.find('#'+view.id)
    elToReplace.after(view.el).remove()
    @registerSubView(view, key)
    view.render()
    view.afterInsert()
    view

  registerSubView: (view, key) ->
    # used to register views which are custom inserted into the view,
    # like views where you add multiple instances of them
    key = @makeSubViewKey(view)
    view.parent = @
    view.parentKey = key
    @subviews[key] = view
    view

  makeSubViewKey: (view) ->
    key = view.id or (view.constructor.name+classCount++)
    key = _.underscored(key)  # handy for autocomplete in dev console
    key

  removeSubView: (view) ->
    view.$el.empty()
    delete @subviews[view.parentKey]
    view.destroy()

    
  #- Utilities

  getQueryVariable: (param, defaultValue) -> BaseView.getQueryVariable(param, defaultValue)
  @getQueryVariable: (param, defaultValue) ->
    query = document.location.search.substring 1
    pairs = (pair.split('=') for pair in query.split '&')
    for pair in pairs when pair[0] is param
      return {'true': true, 'false': false}[pair[1]] ? decodeURIComponent(pair[1])
    defaultValue

  getRootView: ->
    view = @
    view = view.parent while view.parent?
    view

  
  #- Teardown

  destroy: ->
    @stopListening()
    @off()
    @stopListeningToShortcuts()
    @undelegateEvents() # removes both events and subs
    view.destroy() for id, view of @subviews
    $('#modal-wrapper .modal').off 'hidden.bs.modal', @modalClosed
    @[key] = undefined for key, value of @
    @destroyed = true
    @destroy = _.noop

_.extend(BaseView.prototype, FrimFram.BaseClass.prototype)
    
module.exports = BaseView
