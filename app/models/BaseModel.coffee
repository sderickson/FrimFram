storage = require 'lib/storage'

class BaseModel extends Backbone.Model

  #- state flags
  fetching: false
  saving: false
  
  #- Initialization
  
  constructor: ->
    @_attributesChanged = {}
    super(arguments...)
    @_attributesChanged = {}

  initialize: (attributes, options) ->
    super(arguments...)
    options ?= {}
    @setProjection options.project
    console.error("#{@} needs a className set.") if not @constructor.className
      
    @on 'sync', @onLoadedOrAdded, @
    @on 'error', @onError, @
    @on 'add', @onLoadedOrAdded, @
    @on 'invalid', @onInvalid, @
  

  #- Misc

  setProjection: (@project) ->

  type: -> @constructor.className

  schema: ->
    s = @constructor.schema
    if _.isString s then tv4.getSchema(s) else s
    
  #- Callbacks

  onError: ->
    @fetching = @saving = false
    @jqxhr = null

  onLoadedOrAdded: ->
    @fetching = @saving = false
    @jqxhr = null
    @_attributesChanged = {}
    @url = "#{@urlRoot}/#{@id}"
    
  onInvalid: ->
    console.debug "Validation failed for #{@constructor.className}: '#{@get('name') or @}'."
    for error in @validationError
      console.debug "\t", error.dataPath, ':', error.message

    
  #- Get, set, unset overrides

  set: (attributes, options) ->
    throw new Error('Cannot set while fetching.') if (@fetching or @saving) and not (options.xhr or options.headers)
    return super attributes, options
    
  #- Validation
  
  getValidationErrors: ->
    errors = tv4.validateMultiple(@attributes, @constructor.schema or {}).errors
    return errors if errors?.length

  validate: -> @getValidationErrors()

      
  #- Save, fetch overrides
      
  save: (attrs, options) ->
    
    # create options
    options ?= {}
    throw new Error('Cannot wholly save a projected model!') if @project and not options.patch
    originalOptions = _.clone(options)
    options.headers ?= {}
    options.headers['X-Current-Path'] = document.location?.pathname ? 'unknown'
    
    # callbacks
    options.success = (model, res) =>
      originalOptions.success?(@, res)
      @markToRevert() if @_revertAttributes
      options.success = options.error = null  # So the callbacks can be garbage-collected.
    
    options.error = (model, res) =>
      originalOptions.error?(@, res)
      
      # TODO: figure out a better error notification system
#      return unless @notyErrors
#      errorMessage = "Error saving #{@get('name') ? @type()}"
#      noty text: "#{errorMessage}: #{res.status} #{res.statusText}"
      
    options.complete = ->
      options.success = options.error = options.complete = null  # for garbage collection
    
    @saving = true

    return super attrs, options


  fetch: (options) ->
    options ?= {}
    options.data ?= {}
    options.data.project = @project.join(',') if @project
    options.isFetchResult
    
    @jqxhr = super(options)
    @fetching = true
    @jqxhr


module.exports = BaseModel