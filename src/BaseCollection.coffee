class BaseCollection extends Backbone.Collection
  
  dataState: 'standby' # or 'fetching'

  initialize: (models, options) ->
    super(models, options)
    @on 'sync', (-> @dataState = 'standby'), @
    @on 'error', (-> @dataState = 'standby'), @
    if options?.defaultFetchData
      @defaultFetchData = options.defaultFetchData

  fetch: (options) ->
    @dataState = 'fetching'
    if @defaultFetchData
      options ?= {}
      options.data ?= {}
      _.defaults(options.data, @defaultFetchData)
    return super(options)
    
  # At some later point, create save, patch, destroy methods?

    
FrimFram.BaseCollection = BaseCollection 