Router = require 'Router'
runtimeErrorTemplate = require 'templates/common/runtime-error-alert'
rootSchema = require 'schemas/root.schema'

class Application extends FrimFram.BaseClass
  
  #- Initialization
  
  initialize: ->
    @watchForErrors()
    @installSchema()
    $(document).bind 'keydown', @preventBackspace
    @router = new Router()
    Backbone.history.start({ pushState: true })
    @handleNormalUrls()
    _.mixin(_.string.exports())

    
  #- Error reporting
    
  watchForErrors: ->
    window.onerror = (msg, url, line, col, error) ->
      return if $('body').find('.runtime-error-alert').length
      alert = $(runtimeErrorTemplate({errorMessage: msg}))
      $('body').append(alert)
      alert.addClass('in')
      alert.alert()
      close = -> alert.alert('close')
      
      
  #- Install the one root schema, all schemas can be referenced from it
  
  installSchema: ->
    tv4.addSchema rootSchema
    
  
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
    
        
  #- Utilities

  isProduction: -> window.location.href.indexOf('localhost') is -1
    
module.exports = Application