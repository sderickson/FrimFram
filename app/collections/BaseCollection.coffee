BaseModel = require 'models/BaseModel'

module.exports = class BaseCollection extends Backbone.Collection
  loaded: false
  model: null

  initialize: (models, options) ->
    options ?= {}
    @model ?= options.model
    @loaded = options.loaded if options.loaded
    if not @model
      console.error @constructor.name, 'does not have a model defined. This will not do!'
    super(models, options)
    @setProjection options.project
    if options.url then @url = options.url
    @once 'sync', =>
      @loaded = true
    @once 'complete', =>
      @fetching = false

  fetch: (options) ->
    options ?= {}
    if @project
      options.data ?= {}
      options.data.project = @project.join(',')
    @jqxhr = super(options)
    @fetching = true
    @jqxhr

  setProjection: (@project) ->