class BaseCollection extends Backbone.Collection
  
  dataState: 'standby' # or 'fetching'

  initialize: (models, options) ->
    super(models, options)
    @on 'sync', (-> @dataState = 'standby'), @
    @on 'error', (-> @dataState = 'standby'), @

  fetch: (options) ->
    @dataState = 'fetching'
    return super(options)
    
  # At some later point, create save, patch, destroy methods?

    
FrimFram.BaseCollection = BaseCollection 