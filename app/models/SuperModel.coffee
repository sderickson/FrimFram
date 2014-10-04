BaseClass = require 'BaseClass'

module.exports = class SuperModel extends BaseClass

  constructor: ->
    super()
    @maxProgress = 1
    @loading = []
    @onStateChanged = _.throttle(@onStateChanged, 200, {leading: true, trailing: true})

    
  #- Registering models, collections, jqxhrs, custom resources
  
  defaultRegistrationOptions:
    value: 1
    label: '???'
    
  registerModel: (model, options) ->
    if model.isNew() and not model.fetching
      throw new Error('Model should be fetching or loaded.')

    options ?= {}
    _.defaults options, @defaultRegistrationOptions
      
    if model.fetching
      model.loadValue = options.value
      model.loadLabel = options.label
      model.loadType = 'model'
      
      @loading.push(model)
      @onStateChanged()
      
      @listenTo model, 'sync', ->
        @stopListening(model)
        @onStateChanged()
        @registerModel(model)
        
      @listenTo model, 'error', ->
        @stopListening(model)
        @onStateChanged()
      
    else
      collection = @collectionForModel(model)
      extant = collection.find({id: model.id})
      if extant
        @mergeModels(extant, model)
      else
        collection.add(model)

  collectionForModel: (model) ->
    @[model.constructor.className] ?= new Backbone.Collection([], {model: model.constructor})

  registerCollection: (collection, options) ->
    unless collection.fetching or collection.loaded
      throw new Error('Model should be fetching or loaded.')

    options ?= {}
    _.defaults options, @defaultRegistrationOptions

    if collection.fetching
      collection.loadValue = options.value
      collection.loadLabel = options.label
      collection.loadType = 'collection'
      
      @loading.push(collection)
      @onStateChanged()

      @listenTo collection, 'sync', ->
        @stopListening(collection)
        @onStateChanged()
        @registerModel(model) for model in collection.models
        
      @listenTo collection, 'error', ->
        @stopListening(collection)
        @onStateChanged()

    else
      @registerModel(model) for model in collection.models

  registerJQXHR: (jqxhr, options) ->
    options ?= {}
    _.defaults options, @defaultRegistrationOptions
    jqxhr.loadType = 'jqxhr'
    jqxhr.loadValue = options.value
    jqxhr.loadLabel = options.label
    @loading.push(jqxhr)
    
    jqxhr.always(=> @onStateChanged())

  registerCustomResource: (resource, options) ->
    options ?= {}
    _.defaults options, @defaultRegistrationOptions
    resource.loadType = 'custom'
    resource.loadValue = options.value
    resource.loadLabel = options.label
    @loading.push(resource)
    
  markCustomResourceLoaded: (resource) ->
    if not resource in @loading
      throw new Error('Given resource is not listed as loading.')
    resource.loaded = true
    @onStateChanged()

  onStateChanged: =>
    return if @destroyed
    progress = @progress()
    @trigger 'change:progress', { progress: progress.value }
    if progress.value is 1 and progress.denom
      @trigger 'finished-loading', {}
    if progress.value is 1
      @loading = []

  
  #- Merging models

  mergeModels: (model, source) ->
    for key, value of source.attributes
      continue if key is '_id'
      model.project.push(key) if model.project and key not in model.project
      model.set(key, value)
      

  #- Loading status
  
  progress: ->
    denom = 0
    num = 0
    for resource in @loading
      denom += resource.loadValue
      switch resource.loadType
        when 'model' then loaded = !!resource.id
        when 'collection' then loaded = resource.loaded
        when 'jqxhr' then loaded = resource.status is 200
        when 'custom' then loaded = resource.loaded
      num += resource.loadValue if loaded
    
    return {
      num: num
      denom: denom
      value: Math.min(@maxProgress, if denom is 0 then 1 else num / denom)
    }

  finished: -> @progress().value is 1

  setMaxProgress: (@maxProgress) ->

  clearMaxProgress: ->
    @maxProgress = 1
    _.defer @updateProgress

  getResource: (rid) ->
    return @resources[rid]
