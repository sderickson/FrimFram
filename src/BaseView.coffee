
class BaseView extends Backbone.View
  
  template: ''
  shortcuts: {}
  @globals = ['moment']
  @setGlobals: (@globals)


  #- Setup

  constructor: (options) ->
    @events = @superMerge(@, 'events')
    @subviews = {}
    @listenToShortcuts()
    super options
    
    
  #- Rendering functions
    
  render: ->
    # reset subviews
    view.destroy() for id, view of @subviews
    @subviews = {}
    @$el.html @getTemplateResult()
    @afterRender()

  renderSelectors: (selectors...) ->
    newTemplate = $(@getTemplateResult())
    for selector in selectors
      @$el.find(selector).replaceWith(newTemplate.find(selector))

  getTemplateResult: ->
    if _.isString(@template) then @template else @template(@getContext())

  getContext: (pick) ->
    context = {}
    context.pathname = document.location.pathname  # ex. '/play/level'
    context = _.extend context, _.pick(window, BaseView.globals)
    context = _.extend context, _.pick(@, pick) if pick
    context
    
    
  #- Callbacks

  afterRender: _.noop # Good place to insert subviews

  afterInsert: _.noop # Called when view is inserted into the DOM


  #- Shortcuts

  listenToShortcuts: (recurse) ->
    shortcuts = @superMerge('shortcuts')
    for shortcut, func of @shortcuts
      func = @normalizeFunc(func)
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
    elToReplace.after(view.el).remove()
    @registerSubview(view, key)
    view.render()
    view.afterInsert()
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

  getQueryVariable: (param) ->
    BaseView.getQueryVariable(param)
    
  @getQueryVariable: (param) ->
    query = document.location.search.substring 1
    pairs = (pair.split('=') for pair in query.split '&')
    for pair in pairs when pair[0] is param
      return {'true': true, 'false': false}[pair[1]] ? decodeURIComponent(pair[1])
    return

  
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
