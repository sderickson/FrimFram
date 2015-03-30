class BaseModel extends Backbone.Model

  dataState: 'standby' # or 'fetching', 'saving'
  
  initialize: (attributes, options) ->
    super(attributes, options)
    @on 'sync', @onLoadedOrAdded, @
    @on 'add', @onLoadedOrAdded, @
    @on 'error', @onError, @
    
  onError: -> @dataState = 'standby'
  onLoadedOrAdded: -> @dataState = 'standby'

  schema: ->
    s = @constructor.schema
    if _.isString s then tv4.getSchema(s) else s

  onInvalid: ->
    console.debug "Validation failed for #{@constructor.className or @}: '#{@get('name') or @}'."
    for error in @validationError
      console.debug "\t", error.dataPath, ':', error.message

  get: (attr) ->
    if _(attr).contains('.')
      parts = attr.split('.')
      value = @attributes
      for subKey in parts
        subKey = parseInt(subKey) if _.isArray(value)
        value = value?[subKey]
      return value
    else
      return Backbone.Model.prototype.get.apply(@, [attr])

  set: (attributes, options) ->
    if (@dataState isnt 'standby') and not (options.xhr or options.headers)
      throw new Error('Cannot set while fetching or saving.')

    if _.isString(attributes)
      a = {}
      a[attributes] = options
      attributes = a
      options = {}

    for key of attributes
      continue unless _(key).contains('.')
      parts = key.split('.')
      slim = _.pick(@attributes, parts[0])
      clone = _.merge({}, slim)
      value = clone
      for subKey in parts
        parent = value
        subKey = parseInt(subKey) if _.isArray(value)
        value = value?[subKey]
      if parent
        parent[subKey] = attributes[key]
        @set(clone)
      delete attributes[key]

    Backbone.Model.prototype.set.apply(@, [attributes, options])

    return super(attributes, options)

  getValidationErrors: ->
    errors = tv4?.validateMultiple(@attributes, @constructor.schema or {}).errors
    return errors if errors?.length

  validate: -> @getValidationErrors()

  save: (attrs, options) ->
    result = super(attrs, options)
    @dataState = 'saving'
    return result

  fetch: (options) ->
    @dataState = 'fetching'
    return super(options)



FrimFram.BaseModel = BaseModel