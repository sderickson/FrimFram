class Router extends Backbone.Router
  @go = (path) -> -> @routeDirectly path, arguments

  #- Routing functions

  routeToServer: ->
    window.location.reload(true)

  routeDirectly: (path, args) ->
    return document.location.reload() if @currentView?.reloadOnClose
    
    path = "views/#{path}"

    try
      ViewClass = require(path)
    catch error
      if error.toString().search('Cannot find module "' + path + '" from') is -1
        throw error

    ViewClass ?= NotFoundView
    view = new ViewClass({params: args})
    @openView(view)

  #- Opening, closing views
    
  openView: (view) ->
    @closeCurrentView()
    view.render()
    $('body').empty().append(view.el)
    @currentView = view
    view.onInsert()
    
  closeCurrentView: -> @currentView?.destroy()

FrimFram.Router = Router