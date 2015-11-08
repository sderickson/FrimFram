class Application extends FrimFram.BaseClass
  @extend: Backbone.Model.extend

  #- Initialization

  constructor: ->
    @watchForErrors()
    $(document).bind 'keydown', @preventBackspace
    @handleNormalUrls()
    @initialize(arguments...)

  initialize: _.noop

  start: ->
    Backbone.history.start({ pushState: true })


  #- Error reporting

  watchForErrors: ->
    window.addEventListener "error", (e) ->
      return if $('body').find('.runtime-error-alert').length
      alert = $(FrimFram.runtimeErrorTemplate({errorMessage: e.error.message}))
      $('body').append(alert)
      alert.addClass('in')
      alert.alert()


  #- Backspace navigation stopping

  # Prevent Ctrl/Cmd + [ / ], P, S
  @ctrlDefaultPrevented: [219, 221, 80, 83]
  preventBackspace: (event) =>
    if event.keyCode is 8 and not @elementAcceptsKeystrokes(event.srcElement or event.target)
      event.preventDefault()
    else if (key.ctrl or key.command) and not key.alt and event.keyCode in Application.ctrlDefaultPrevented
      event.preventDefault()

  elementAcceptsKeystrokes: (el) ->
    # http://stackoverflow.com/questions/1495219/how-can-i-prevent-the-backspace-key-from-navigating-back
    el ?= document.activeElement
    tag = el.tagName.toLowerCase()
    type = el.type?.toLowerCase()
    textInputTypes = ['text', 'password', 'file', 'number', 'search', 'url', 'tel', 'email', 'date', 'month', 'week', 'time', 'datetimelocal']
    # not radio, checkbox, range, or color
    return (tag is 'textarea' or (tag is 'input' and type in textInputTypes) or el.contentEditable in ['', 'true']) and not (el.readOnly or el.disabled)


  #- Single-page web app URLs w/out hashbang

  handleNormalUrls: ->
    # http://artsy.github.com/blog/2012/06/25/replacing-hashbang-routes-with-pushstate/
    $(document).on 'click', "a[href^='/']", (event) ->
      href = $(event.currentTarget).attr('href')
      passThrough = href.indexOf('sign_out') >= 0
      if !passThrough && !event.altKey && !event.ctrlKey && !event.metaKey && !event.shiftKey
        event.preventDefault()
        url = href.replace(/^\//,'').replace('\#\!\/','')
        app.router.navigate url, { trigger: true }
        return false


FrimFram.Application = Application