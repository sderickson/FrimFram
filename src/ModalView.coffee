class ModalView extends FrimFram.View
  @visibleModal: null

  className: 'modal fade'
  destroyOnHidden: true

  onRender: ->
    super()

    # proxy Bootstrap events to Backbone View events
    modal = @
    @$el.on 'show.bs.modal', -> modal.trigger 'show'
    @$el.on 'shown.bs.modal', ->
      modal.onInsert()
      modal.trigger 'shown'
    @$el.on 'hide.bs.modal', -> modal.trigger 'hide'
    @$el.on 'hidden.bs.modal', -> modal.onHidden()
    @$el.on 'loaded.bs.modal', -> modal.trigger 'loaded'

  hide: (fast) ->
    @$el.removeClass('fade') if fast
    @$el.modal('hide')

  show: (fast) ->
    ModalView.visibleModal?.hide(true)
    @render()
    @$el.removeClass('fade') if fast
    $('body').append @$el
    @$el.modal('show')
    ModalView.visibleModal = @

  toggle: -> @$el.modal('toggle')

  onHidden: ->
    ModalView.visibleModal = null if ModalView.visibleModal is @
    @trigger 'hidden'
    @destroy() if @destroyOnHidden

FrimFram.ModalView = ModalView