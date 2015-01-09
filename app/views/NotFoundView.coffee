RootView = require 'views/kinds/RootView'
template = require 'templates/not-found-view'

module.exports = class NotFoundView extends RootView
  id: 'not-found-view'
  template: template
