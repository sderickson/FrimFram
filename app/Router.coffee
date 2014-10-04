NotFoundView = require('views/NotFoundView')
go = (path) -> -> @routeDirectly path, arguments

module.exports = class CocoRouter extends Backbone.Router

  #- Routing map
  
  routes:
    '': go('HomeView')  # This will go somewhere deprecated when FrontView is done.
    'db/*path': 'routeToServer'
    'file/*path': 'routeToServer'
    'test(/*subpath)': go('TestView')
    '*name': 'showNotFoundView'
    
    
  #- Routing functions

  routeToServer: (e) ->
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
    view = new ViewClass({}, args...)
    @openView(view)

  showNotFoundView: ->
    @openView new NotFoundView()

    
  #- Opening, closing views
    
  openView: (view) ->
    @closeCurrentView()
    view.render()
    $('body').empty().append(view.el)
    @currentView = view
    view.afterInsert()
    
  closeCurrentView: -> @currentView?.destroy()
