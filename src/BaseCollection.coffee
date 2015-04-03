class BaseCollection extends Backbone.Collection
  
  dataState: 'standby' # or 'fetching'

  initialize: (models, options) ->
    super(models, options)
    if options?.defaultFetchData
      @defaultFetchData = options.defaultFetchData

  fetch: (options) ->
    @dataState = 'fetching'
    options = FrimFram.wrapBackboneRequestCallbacks(options)
    if @defaultFetchData
      options.data ?= {}
      _.defaults(options.data, @defaultFetchData)
    return super(options)
    
  # At some later point, create save, patch, destroy methods?

    
FrimFram.BaseCollection = BaseCollection 