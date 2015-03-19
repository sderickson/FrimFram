class BaseCollection extends Backbone.Collection
  loaded: false

  initialize: (models, options) ->
    options ?= {}
    @loaded = options.loaded if options.loaded
    super(models, options)
    @setProjection options.project
    @once 'sync', (-> @loaded = true), @
    @once 'complete', (-> @fetching = false), @

  fetch: (options) ->
    options ?= {}
    if @project
      options.data ?= {}
      options.data.project = @project.join(',')
    @fetching = true
    # TODO: set this up to not need to save jqxhr objects.
    # Save just the info we need for reporting errors, or something.
#    @jqxhr = super(options)
    return super(options)

  setProjection: (@project) ->
    
FrimFram.BaseCollection = BaseCollection 