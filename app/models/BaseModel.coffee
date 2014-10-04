storage = require 'lib/storage'
deltasLib = require 'lib/deltas'

module.exports = BaseModel = class BaseModel extends Backbone.Model
  idAttribute: '_id'
  
  #- state flags
  fetching: false
  saving: false
  
  #- internal use attribute objects
  _revertAttributes: null # A deep copy of the unchanged model since the last save. Only created when changes are made.
  _defaultAttributes: null # A cache of default properties.
  _changedAttributes: null # A set for keeping track of exactly what attributes have changed.
  
  saveBackups: false
  
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
    @saveBackup = _.debounce(@saveBackup, 500)


  #- Misc

  setProjection: (@project) ->

  type: -> @constructor.className

  schema: -> return @constructor.schema
    
  #- Callbacks

  onError: ->
    @fetching = @saving = false
    @jqxhr = null

  onLoadedOrAdded: ->
    @fetching = @saving = false
    @jqxhr = null
    @_attributesChanged = {}
    @url = "#{@urlRoot}/#{@id}"
    @loadFromBackup() unless @saveBackups
    
  onInvalid: ->
    console.debug "Validation failed for #{@constructor.className}: '#{@get('name') or @}'."
    for error in @validationError
      console.debug "\t", error.dataPath, ':', error.message

    
  #- Get, set, unset overrides
    
  get: (attribute, withDefault=false) ->
    # sanity checks
    if @project and attribute not in @project
      throw new Error("Attribute #{attribute} is not included in this projected model.")
    
    # TODO: Have it only populate the property being defaulted.
    if withDefault
      if @_defaultAttributes is null then @buildDefaultAttributes()
      return @_defaultAttributes[attribute]
    else
      super(attribute)

  set: (attributes, options) ->
    # sanity checks
    throw new Error('Cannot set while fetching.') if (@fetching or @saving) and not (options.xhr or options.headers)
    attributeKeys = if _.isString(attributes) then [attributes] else _.keys(attributes)
    for attribute in attributeKeys
      if @project and attribute not in @project
        throw new Error("Cannot set to attribute #{attribute} because it is not part of the projection!")

    # state updates
    @_attributesChanged[attribute] = true for attribute in attributeKeys
    delete @_defaultAttributes
    @markToRevert() unless @_revertAttributes or @project or _.isEmpty(@attributes) or options?.fromMerge
    @saveBackup() if @saveBackups
    
    return super attributes, options
    
  unset: (attribute, options) ->
    super(arguments...)
    delete @attributes[attribute]

    
  #- Defaults

  attributesWithDefaults: undefined

  buildDefaultAttributes: ->
    clone = $.extend true, {}, @attributes
    # TODO: Have one big tv4 that has all schemas and that everything shares
    thisTV4 = tv4.freshApi()
    thisTV4.addSchema('#', @schema())
    thisTV4.addSchema('metaschema', require('schemas/metaschema'))
    TreemaNode.utils.populateDefaults(clone, @schema(), thisTV4)
    @_defaultAttributes = clone

    
  #- Backups
    
  loadFromBackup: ->
    if existing = storage.load @id
      @set(existing, {silent: true})

  saveBackup: -> @saveBackupNow()
  
  saveBackupNow: -> storage.save(@id, @attributes)

  clearBackup: -> storage.remove @id


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
      @clearBackup()
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


  #- Patch
    
  patch: (options) ->
    keys = _.keys(@_attributesChanged)
    return unless keys.length
    options ?= {}
    options.patch = true
    attrs = {_id: @id}
    attrs[key] = @attributes[key] for key in keys
    @save(attrs, options)


  #- Revert

  markToRevert: ->
    @_revertAttributes = $.extend(true, {}, @attributes)

  revert: ->
    @clear({silent: true})
    @set(@_revertAttributes) if @_revertAttributes
    @clearBackup()

  hasLocalChanges: ->
    return not _.isEmpty(@_changedAttributes)


  #- Permissions
    
  hasReadAccess: (actor) ->
    actor ?= me
    return true if actor.isAdmin()
    for permission in (@get('permissions', true) ? [])
      if permission.target is 'public' or actor.get('_id') is permission.target
        return true if permission.access in ['owner', 'read']
    return false

  hasWriteAccess: (actor) ->
    actor ?= me
    return true if actor.isAdmin()
    for permission in (@get('permissions', true) ? [])
      if permission.target is 'public' or actor.get('_id') is permission.target
        return true if permission.access in ['owner', 'write']
    return false

  getOwner: ->
    ownerPermission = _.find @get('permissions', true), access: 'owner'
    ownerPermission?.target
    
    
  #- Deltas

  getDelta: ->
    differ = deltasLib.makeJSONDiffer()
    differ.diff @_revertAttributes, @attributes

  getDeltaWith: (otherModel) ->
    differ = deltasLib.makeJSONDiffer()
    differ.diff @attributes, otherModel.attributes

  applyDelta: (delta) ->
    newAttributes = $.extend(true, {}, @attributes)
    try
      jsondiffpatch.patch newAttributes, delta
    catch error
      console.error 'Error applying delta\n', JSON.stringify(delta, null, '\t'), '\n\nto attributes\n\n', newAttributes
      return false
    for key, value of newAttributes
      delete newAttributes[key] if _.isEqual value, @attributes[key]

    @set newAttributes
    return true

  getExpandedDelta: ->
    delta = @getDelta()
    deltasLib.expandDelta(delta, @_revertAttributes, @schema())

  getExpandedDeltaWith: (otherModel) ->
    delta = @getDeltaWith(otherModel)
    deltasLib.expandDelta(delta, @attributes, @schema())
