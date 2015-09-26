class Model extends Backbone.Model

  state: 'standby' # or 'fetching', 'saving'

  created: -> new Date(parseInt(@id.substring(0, 8), 16) * 1000)

  constructor: (attributes, options) ->
    super(attributes, options)
    @on 'add', @onAdded, @

  onAdded: -> @state = 'standby'

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
    if (@state isnt 'standby') and not (options.xhr or options.headers)
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
    options = FrimFram.wrapBackboneRequestCallbacks(options)
    result = super(attrs, options)
    @state = 'saving' if result
    return result

  fetch: (options) ->
    options = FrimFram.wrapBackboneRequestCallbacks(options)
    @state = 'fetching'
    return super(options)



FrimFram.BaseModel = FrimFram.Model = Model