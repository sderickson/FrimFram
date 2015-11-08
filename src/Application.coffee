class Application extends FrimFram.BaseClass
  @extend: Backbone.Model.extend

  constructor: (options) ->
    options = _.defaults {}, options, {
      watchForErrors: true
      preventBackspace: true
    }
    @watchForErrors() if options.watchForErrors
    $(document).bind('keydown', @preventBackspace) if options.preventBackspace
    @initialize(arguments...)

  initialize: _.noop

  start: ->
    Backbone.history.start({ pushState: true })

  watchForErrors: ->
    window.addEventListener "error", (e) ->
      return if $('body').find('.runtime-error-alert').length
      alert = $(FrimFram.runtimeErrorTemplate({errorMessage: e.error.message}))
      $('body').append(alert)
      alert.addClass('in')
      alert.alert()

  preventBackspace: (event) ->
    if event.keyCode is 8 and not @elementAcceptsKeystrokes(event.srcElement or event.target)
      event.preventDefault()

  elementAcceptsKeystrokes: (el) ->
    # http://stackoverflow.com/questions/1495219/how-can-i-prevent-the-backspace-key-from-navigating-back
    el ?= document.activeElement
    tag = el.tagName.toLowerCase()
    type = el.type?.toLowerCase()
    textInputTypes = ['text', 'password', 'file', 'number', 'search', 'url', 'tel', 'email', 'date', 'month', 'week', 'time', 'datetimelocal']
    # not radio, checkbox, range, or color
    return (tag is 'textarea' or (tag is 'input' and type in textInputTypes) or el.contentEditable in ['', 'true']) and not (el.readOnly or el.disabled)


FrimFram.Application = Application