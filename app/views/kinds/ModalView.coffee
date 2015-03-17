BaseView = require './BaseView'

module.exports = class ModalView extends BaseView
  className: 'modal fade'

  afterRender: ->
    super()

    modal = @
    @$el.on 'show.bs.modal', -> modal.trigger 'show'
    @$el.on 'shown.bs.modal', -> modal.trigger 'shown'
    @$el.on 'hide.bs.modal', -> modal.trigger 'hide'
    @$el.on 'hidden.bs.modal', -> modal.trigger 'hidden'
    @$el.on 'loaded.bs.modal', -> modal.trigger 'loaded'
    
  hide: -> @$el.modal('hide')
  show: -> @$el.modal('show')
  toggle: -> @$el.modal('toggle')

  destroy: ->
    @hide() unless @hidden
    super()
