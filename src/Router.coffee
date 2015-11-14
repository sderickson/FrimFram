class Router extends Backbone.Router
  @go = (path) -> -> @routeDirectly path, arguments

  #- Routing functions

  routeToServer: ->
    window.location.reload(true)

  routeDirectly: (path, args) ->
    return document.location.reload() if @view?.reloadOnClose
    leavingMessage = _.result(@view, 'onLeaveMessage')
    if leavingMessage
      if not confirm(leavingMessage)
        return @navigate(this.path, {replace: true})

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
    @view = view
    @path = document.location.pathname + document.location.search
    view.onInsert()

  closeCurrentView: -> @view?.destroy()

  setupOnLeaveSite: ->
    window.addEventListener "beforeunload", (e) =>
      leavingMessage = _.result(@view, 'onLeaveMessage')
      if leavingMessage
        e.returnValue = leavingMessage
        return leavingMessage

FrimFram.Router = Router
