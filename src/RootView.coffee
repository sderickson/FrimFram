class RootView extends FrimFram.View

  onInsert: ->
    super(arguments...)
    title = _.result(@, 'title') or _.result(RootView, 'globalTitle') or @constructor.name
    $('title').text(title)

  title: _.noop

  @globalTitle: _.noop

FrimFram.RootView = RootView