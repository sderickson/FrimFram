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

  set: (attributes, options) ->
    if (@dataState isnt 'standby') and not (options.xhr or options.headers)
      throw new Error('Cannot set while fetching or saving.')
    return super(attributes, options)

  getValidationErrors: ->
    errors = tv4?.validateMultiple(@attributes, @constructor.schema or {}).errors
    return errors if errors?.length

  validate: -> @getValidationErrors()

  save: (attrs, options) ->
    @dataState = 'saving'
    return super(attrs, options)

  fetch: (options) ->
    @dataState = 'fetching'
    return super(options)



FrimFram.BaseModel = BaseModel