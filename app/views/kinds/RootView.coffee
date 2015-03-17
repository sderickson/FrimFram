BaseView = require './BaseView'

module.exports = class RootView extends BaseView

  afterRender: ->
    super(arguments...)

    if app.isProduction()
      title = @getTitle() or '???'
    else
      title = @getTitle() or @constructor.name

    $('title').text(title)

  getTitle: _.noop
