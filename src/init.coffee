window.FrimFram = {
  isProduction: -> window.location.href.indexOf('localhost') is -1
    
  wrapBackboneRequestCallbacks: (options) ->
    options ?= {}
    originalOptions = _.clone(options)
    options.success = (model) ->
      model.dataState = 'standby'
      originalOptions.success?(arguments...)
    options.error = (model) ->
      model.dataState = 'standby'
      originalOptions.error?(arguments...)
    options.complete = (model) ->
      model.dataState = 'standby'
      originalOptions.complete?(arguments...)
    return options
}
