module.exports = BaseClass = class BaseClass

  #- Class methods
  
  @superMerge = (obj, propertyName) ->
    combined = {}
    while value = obj?[propertyName]
      _.defaults(combined, value)
      obj = obj.__proto__ or Object.getPrototypeOf(obj)
    combined

  @normalizeFunc = (funcThing, object) ->
    object ?= {}
    if _.isString(funcThing)
      if not func = object[funcThing]
        console.error "Could not find method #{funcThing} in object", object
        return _.noop
      funcThing = func
    return funcThing

    
  #- Setup

  constructor: ->
    @subscriptions = BaseClass.superMerge(@, 'subscriptions')
    @shortcuts = BaseClass.superMerge(@, 'shortcuts')
    @listenToSubscriptions()
    @listenToShortcuts()
    _.extend(@, Backbone.Events)

    
  #- Backbone Mediator Subscriptions

  listenToSubscriptions: ->
    for channel, func of @subscriptions
      func = BaseClass.normalizeFunc(func, @)
      Backbone.Mediator.subscribe(channel, func, @)

  addNewSubscription: (channel, func) ->
    return unless @subscriptions[channel] is undefined
    func = BaseClass.normalizeFunc(func, @)
    @subscriptions[channel] = func
    Backbone.Mediator.subscribe(channel, func, @)

  unsubscribeAll: ->
    for channel, func of @subscriptions
      func = BaseClass.normalizeFunc(func, @)
      Backbone.Mediator.unsubscribe(channel, func, @)

      
  #- keymaster keyboard shortcuts

  listenToShortcuts: ->
    return if _.isEmpty(@shortcuts)
    @scope = _.uniqueId('class-scope-')
    for shortcut, func of @shortcuts
      func = BaseClass.normalizeFunc(func, @)
      key(shortcut, @scope, _.bind(func, @))

  stopListeningToShortcuts: ->
    return unless @scope
    key.deleteScope(@scope)

    
  #- Teardown

  destroy: ->
    # clear Backbone Events
    @off()
    @unsubscribeAll()

    # clear keymaster shortcuts
    @stopListeningToShortcuts()

    # salt the earth
    delete @[key] for key of @
    @destroyed = true
