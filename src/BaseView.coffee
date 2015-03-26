
class BaseView extends Backbone.View
  
  template: ''
  shortcuts: {}
  @globals = ['moment']
  @setGlobals: (@globals) ->


  #- Setup

  constructor: (options) ->
    @events = @superMerge('events')
    @subviews = {}
    @listenToShortcuts()
    super options
    
    
  #- Rendering functions
    
  render: ->
    # reset subviews
    view.destroy() for id, view of @subviews
    @subviews = {}
    @$el.html @getTemplateResult()
    @onRender()

  renderSelectors: (selectors...) ->
    newTemplate = $(@getTemplateResult())
    for selector in selectors
      @$el.find(selector).replaceWith(newTemplate.find(selector))

  getTemplateResult: ->
    if _.isString(@template) then @template else @template(@getContext())
    
  initContext: (pickPredicate) ->
    context = {}
    context.pathname = document.location.pathname  # ex. '/play/level'
    context = _.extend context, _.pick(window, BaseView.globals)
    context = _.extend context, _.pick(@, pickPredicate, @) if pickPredicate
    context

  getContext: -> @initContext()
    
    
  #- Callbacks

  onRender: _.noop # Good place to insert subviews

  onInsert: _.noop # Called when view is inserted into the DOM


  #- Shortcuts

  listenToShortcuts: (recurse) ->
    shortcuts = @superMerge('shortcuts')
    if @scope
      @stopListeningToShortcuts()
    else
      @scope = _.uniqueId('view-scope-')
    for shortcut, func of @shortcuts
      func = @[func] if not _.isFunction(func)
      continue unless func
      key(shortcut, @scope, _.bind(func, @))
    if recurse
      for viewID, view of @subviews
        view.listenToShortcuts(true)

  stopListeningToShortcuts: (recurse) ->
    key.deleteScope(@scope)
    if recurse
      for viewID, view of @subviews
        view.stopListeningToShortcuts(true)


  #- Subviews

  insertSubview: (view, elToReplace=null) ->
    # used to insert views with ids
    key = @makeSubviewKey(view)
    @subviews[key].destroy() if key of @subviews
    elToReplace ?= @$el.find('#'+view.id)
    if not elToReplace.length
      throw new Error('Error inserting subview: do not have element for it to replace.')
    elToReplace.after(view.el).remove()
    @registerSubview(view, key)
    view.render()
    view.onInsert()
    view

  registerSubview: (view, key) ->
    # used to register views which are custom inserted into the view,
    # like views where you add multiple instances of them
    key ?= @makeSubviewKey(view)
    @subviews[key] = view
    view

  makeSubviewKey: (view) ->
    key = view.id or (_.uniqueId(view.constructor.name))
    key = _.underscored(key)  # handy for autocomplete in dev console
    key

  removeSubview: (view) ->
    view.$el.empty()
    key = _.findKey @subviews, (v) -> v is view 
    delete @subviews[key] if key
    view.destroy()

      
  #- Utilities

  getQueryParam: (param) ->
    BaseView.getQueryParam(param)
    
  @getQueryParam: (param) ->
    query = @getQueryString()
    pairs = (pair.split('=') for pair in query.split '&')
    for pair in pairs when pair[0] is param
      return {'true': true, 'false': false}[pair[1]] ? decodeURIComponent(pair[1])
    return
    
  @getQueryString: -> document.location.search.substring 1

  
  #- Teardown

  destroy: ->
    @remove()
    @stopListeningToShortcuts()
    view.destroy() for view in _.values(@subviews)
    delete @[key] for key, value of @
    @destroyed = true
    @destroy = _.noop

_.defaults(BaseView.prototype, FrimFram.BaseClass.prototype)
    
FrimFram.BaseView = BaseView
