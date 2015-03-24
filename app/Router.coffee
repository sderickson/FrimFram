NotFoundView = require('views/NotFoundView')
go = FrimFram.Router.go

class Router extends FrimFram.Router

  #- Routing map
  
  routes:
    '': go('HomeView')
    
    'db/*path': 'routeToServer'
    
    'file/*path': 'routeToServer'
    
    'test/client(/*subpath)': go('ClientTestView')
    'test/server(/*subpath)': go('ServerTestView')
    
    '*name': 'showNotFoundView'
    
  showNotFoundView: ->
    @openView new NotFoundView()

module.exports = Router