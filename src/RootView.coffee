class RootView extends FrimFram.BaseView

  onInsert: ->
    super(arguments...)
    title = _.result(@, 'title') or @constructor.name
    $('title').text(title)

  title: _.noop

FrimFram.RootView = RootView