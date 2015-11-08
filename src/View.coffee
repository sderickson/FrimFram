
class View extends Backbone.View

  template: ''
  shortcuts: {}
  @globalContext = {
    'moment': window.moment
  }
  @extendGlobalContext: (globals) -> @globalContext = _.extend(@globalContext, globals)


  #- Setup

  constructor: (options) ->
    @subviews = {}
    @listenToShortcuts()
    super arguments...


  #- Rendering functions

  render: ->
    # reset subviews
    view.destroy() for id, view of @subviews
    @subviews = {}
    @$el.html @getTemplateResult()
    @onRender()

  renderSelectors: (selectors...) ->
    newTemplate = $('<div>'+@getTemplateResult()+'</div>')
    for selector, i in selectors
      for elPair in _.zip(@$el.find(selector), newTemplate.find(selector))
        $(elPair[0]).replaceWith($(elPair[1]))

  getTemplateResult: ->
    if _.isString(@template) then @template else @template(@getContext())

  initContext: (pickPredicate) ->
    context = {}
    context.pathname = document.location.pathname  # ex. '/play/level'
    context = _.defaults context, View.globalContext
    context = _.extend context, _.pick(@, pickPredicate, @) if pickPredicate
    context

  getContext: -> @initContext()


  #- Callbacks

  onRender: _.noop # Good place to insert subviews

  onInsert: _.noop # Called when view is inserted into the DOM


  #- Shortcuts

  listenToShortcuts: (recurse) ->
    return unless @shortcuts
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
    oldSubview = @subviews[key]
    elToReplace ?= @$el.find('#'+view.id)
    if not elToReplace.length
      throw new Error('Error inserting subview: do not have element for it to replace.')
    elToReplace.after(view.el).remove()
    @registerSubview(view, key)
    view.render()
    view.onInsert()
    oldSubview?.destroy()
    view

  registerSubview: (view, key) ->
    # used to register views which are custom inserted into the view,
    # like views where you add multiple instances of them
    key ?= @makeSubviewKey(view)
    @subviews[key] = view
    view

  makeSubviewKey: (view) ->
    key = view.id or (_.uniqueId(view.constructor.name))
    key = _.snakeCase(key)  # handy for autocomplete in dev console
    key

  removeSubview: (view) ->
    view.$el.empty()
    newEl = view.$el.clone()
    view.$el.replaceWith(newEl)
    key = _.findKey @subviews, (v) -> v is view
    delete @subviews[key] if key
    view.destroy()


  #- Utilities

  getQueryParam: (param) ->
    View.getQueryParam(param)

  @getQueryParam: (param) ->
    query = @getQueryString()
    pairs = (pair.split('=') for pair in query.split '&')
    for pair in pairs when pair[0] is param
      return decodeURIComponent(pair[1].replace(/\+/g, '%20'))
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

_.defaults(View.prototype, FrimFram.BaseClass.prototype)

FrimFram.View = FrimFram.BaseView = View
