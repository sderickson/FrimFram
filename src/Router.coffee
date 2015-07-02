class Router extends Backbone.Router
  @go = (path) -> -> @routeDirectly path, arguments

  #- Routing functions

  routeToServer: ->
    window.location.reload(true)

  routeDirectly: (path, args) ->
    return document.location.reload() if @currentView?.reloadOnClose
    leavingMessage = _.result(@currentView, 'onLeaveMessage')
    if leavingMessage
      if not confirm(leavingMessage)
        return @navigate(this.currentPath, {replace: true})

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
    @currentPath = document.location.pathname + document.location.search
    view.onInsert()

  closeCurrentView: -> @currentView?.destroy()

  setupOnLeaveSite: ->
    window.addEventListener "beforeunload", (e) =>
      leavingMessage = _.result(@currentView, 'onLeaveMessage')
      if leavingMessage
        e.returnValue = leavingMessage
        return leavingMessage

FrimFram.Router = Router