class ModalView extends FrimFram.BaseView
  @visibleModal: null

  className: 'modal fade'
  destroyOnHidden: true

  afterRender: ->
    super()

    # proxy Bootstrap events to Backbone View events
    modal = @
    @$el.on 'show.bs.modal', -> modal.trigger 'show'
    @$el.on 'shown.bs.modal', ->
      modal.afterInsert()
      modal.trigger 'shown'
    @$el.on 'hide.bs.modal', -> modal.trigger 'hide'
    @$el.on 'hidden.bs.modal', -> modal.onHidden()
    @$el.on 'loaded.bs.modal', -> modal.trigger 'loaded'
    
  hide: (fast) ->
    @$el.removeClass('fade') if fast
    @$el.modal('hide')

  show: ->
    ModalView.visibleModal?.hide(true)
    @render()
    $('body').append @$el
    @$el.modal('show')
    ModalView.visibleModal = @

  toggle: -> @$el.modal('toggle')

  onHidden: ->
    ModalView.visibleModal = null if ModalView.visibleModal is @
    @trigger 'hidden'
    @destroy() if @destroyOnHidden

FrimFram.ModalView = ModalView