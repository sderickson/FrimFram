class RootView extends FrimFram.BaseView

  afterInsert: ->
    super(arguments...)

    if app.isProduction()
      title = @getTitle() or '???'
    else
      title = @getTitle() or @constructor.name

    $('title').text(title)

  getTitle: _.noop

FrimFram.RootView = RootView