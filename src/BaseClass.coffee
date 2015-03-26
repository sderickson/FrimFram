class BaseClass
  superMerge: (propertyName) ->
    combined = {}
    obj = @
    while obj
      value = obj?[propertyName]
      _.defaults(combined, value)
      obj = obj.__proto__ or Object.getPrototypeOf(obj)
    combined

  listenToShortcuts: ->
    shortcuts = @superMerge('shortcuts')
    if @scope
      @stopListeningToShortcuts()
    else
      @scope = _.uniqueId('class-scope-')
    for shortcut, func of shortcuts
      func = @[func] if not _.isFunction(func)
      continue unless func
      key(shortcut, @scope, _.bind(func, @))

  stopListeningToShortcuts: ->
    key.deleteScope(@scope)

  destroy: ->
    @off() # clear Backbone Events
    @stopListeningToShortcuts() # clear keymaster shortcuts
    delete @[key] for key of @ # salt the earth
    @destroyed = true
    @destroy = _.noop

_.extend(BaseClass.prototype, Backbone.Events)

FrimFram.BaseClass = BaseClass