window.FrimFram = {
  isProduction: -> window.location.href.indexOf('localhost') is -1
    
  wrapBackboneRequestCallbacks: (options) ->
    options ?= {}
    originalOptions = _.clone(options)
    options.success = (model) ->
      model.state = 'standby'
      originalOptions.success?(arguments...)
    options.error = (model) ->
      model.state = 'standby'
      originalOptions.error?(arguments...)
    options.complete = (model) ->
      model.state = 'standby'
      originalOptions.complete?(arguments...)
    return options
}
