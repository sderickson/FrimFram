class Modal extends FrimFram.View
  @visibleModal: null

  className: 'modal fade'
  destroyOnHidden: true

  onRender: ->
    super()

    # proxy Bootstrap events to Backbone View events
    modal = @
    @$el.on 'show.bs.modal', (event) ->
      modal.trigger 'show', event
    @$el.on 'shown.bs.modal', (event) ->
      modal.trigger 'shown', event
      modal.onInsert()
    @$el.on 'hide.bs.modal', (event) ->
      modal.trigger 'hide', event
    @$el.on 'hidden.bs.modal', (event) ->
      modal.trigger 'hidden', event
      modal.onHidden()
    @$el.on 'loaded.bs.modal', (event) ->
      modal.trigger 'loaded', event

  hide: (fast) ->
    @$el.removeClass('fade') if fast
    @$el.modal('hide')

  show: (fast) ->
    Modal.visibleModal?.hide(true)
    @render()
    @$el.removeClass('fade') if fast
    $('body').append @$el
    @$el.modal('show')
    Modal.visibleModal = @

  toggle: -> @$el.modal('toggle')

  onHidden: ->
    Modal.visibleModal = null if Modal.visibleModal is @
    @destroy() if @destroyOnHidden

FrimFram.Modal = Modal
