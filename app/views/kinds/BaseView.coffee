SuperModel = require 'models/SuperModel'
BaseClass = require 'BaseClass'

loadingScreenTemplate = require 'templates/common/loading-screen'
loadingErrorTemplate = require 'templates/common/loading-screen-error'

visibleModal = null
waitingModal = null

module.exports = class BaseView extends Backbone.View
  
  #- Default properties
  
  template: -> ''

  events:
    'click .retry-loading-resource': 'onRetryResource'
    'click .skip-loading-resource': 'onSkipResource'

  subscriptions: {}
  shortcuts: {}

  loadProgress:
    progress: 0

    
  #- Setup

  constructor: (options) ->
    
    # TODO: work on supermodel stuff
    @loadProgress = _.cloneDeep @loadProgress
    @supermodel ?= new SuperModel()
    @options = options
    if options?.supermodel # kind of a hacky way to get each view to store its own progress
      @supermodel.models = options.supermodel.models
      @supermodel.collections = options.supermodel.collections
      @supermodel.shouldSaveBackups = options.supermodel.shouldSaveBackups

    @subscriptions = BaseClass.superMerge(@, 'subscriptions')
    @events = BaseClass.superMerge(@, 'events')
    @scope = _.uniqueId('view-scope-')
    @shortcuts = BaseClass.superMerge(@, 'shortcuts')
    @subviews = {}
    @listenToShortcuts()
    @updateProgressBar = _.debounce @updateProgressBar, 100
    # Backbone.Mediator handles subscription setup/teardown automatically

    @listenTo(@supermodel, 'finished-loading', @onLoaded)
    @listenTo(@supermodel, 'progress-changed', @updateProgress)
    # TODO: Fix failed handler
    @listenTo(@supermodel, 'failed', @onResourceLoadFailed)

    super options
    
    
  #- Rendering functions, callbacks
    
  render: ->
    # reset subviews
    view.destroy() for id, view of @subviews
    @subviews = {}
    
    # render to element
    html = @getTemplateResult()
    @$el.html html

    # loading screen
    if @supermodel.finished() then @hideLoading() else @showLoading()

    @afterRender()
    @
    
  renderSelectors: (selectors...) ->
    newTemplate = $(@getTemplateResult())

    for selector in selectors
      @$el.find(selector).replaceWith(newTemplate.find(selector))

    @delegateEvents()

  getTemplateResult: ->
    if _.isString(@template)
      return @template
    else
      return @template(@getContext())

  afterRender: ->

  getContext: (pick) ->
    context = {}
    context.pathname = document.location.pathname  # ex. '/play/level'
    context.moment = moment
    context = _.extend context, _.pick(@, pick) if pick
    context

  afterInsert: ->

  onLoaded: -> @render()


  #- Loading progress

  updateProgress: (progress) ->
    @loadProgress.progress = progress if progress > @loadProgress.progress
    @updateProgressBar(progress)

  updateProgressBar: (progress) =>
    prog = "#{parseInt(progress*100)}%"
    @$el?.find('.loading-container .progress-bar').css('width', prog)

  onResourceLoadFailed: (e) ->
    r = e.resource
    @$el.find('.loading-container .errors').append(loadingErrorTemplate({
      status: r.jqxhr?.status
      name: r.name
      resourceIndex: r.rid,
      responseText: r.jqxhr?.responseText
    })).i18n()
    @$el.find('.progress').hide()

  onRetryResource: (e) ->
    res = @supermodel.getResource($(e.target).data('resource-index'))
    # different views may respond to this call, and not all have the resource to reload
    return unless res and res.isFailed
    res.load()
    @$el.find('.progress').show()
    $(e.target).closest('.loading-error-alert').remove()

  onSkipResource: (e) ->
    res = @supermodel.getResource($(e.target).data('resource-index'))
    return unless res and res.isFailed
    res.markLoaded()
    @$el.find('.progress').show()
    $(e.target).closest('.loading-error-alert').remove()

    
  #- Modals

  toggleModal: (e) ->
    if $(e.currentTarget).prop('target') is '_blank'
      return true
    # special handler for opening modals that are dynamically loaded, rather than static in the page. It works (or should work) like Bootstrap's modals, except use coco-modal for the data-toggle value.
    elem = $(e.target)
    return unless elem.data('toggle') is 'coco-modal'
    target = elem.data('target')
    Modal = require 'views/'+target
    e.stopPropagation()
    @openModalView new Modal supermodel: @supermodal

  openModalView: (modalView, softly=false) ->
    return if waitingModal # can only have one waiting at once
    if visibleModal
      waitingModal = modalView
      return if softly
      return visibleModal.hide() if visibleModal.$el.is(':visible') # close, then this will get called again
      return @modalClosed(visibleModal) # was closed, but modalClosed was not called somehow
    modalView.render()
    $('#modal-wrapper').empty().append modalView.el
    modalView.afterInsert()
    visibleModal = modalView
    modalOptions = {show: true, backdrop: if modalView.closesOnClickOutside then true else 'static'}
    $('#modal-wrapper .modal').modal(modalOptions).on 'hidden.bs.modal', @modalClosed
    window.currentModal = modalView
    @getRootView().stopListeningToShortcuts(true)
    Backbone.Mediator.publish 'modal:opened', {}

  modalClosed: =>
    visibleModal.willDisappear() if visibleModal
    visibleModal.destroy()
    visibleModal = null
    window.currentModal = null
    #$('#modal-wrapper .modal').off 'hidden.bs.modal', @modalClosed
    if waitingModal
      wm = waitingModal
      waitingModal = null
      @openModalView(wm)
    else
      @getRootView().listenToShortcuts(true)
      Backbone.Mediator.publish 'modal:closed', {}

      
  #- Loading RootViews

  showLoading: ($el=@$el) ->
    $el.find('>').addClass('hidden')
    $el.append loadingScreenTemplate()
    @_lastLoading = $el

  hideLoading: ->
    return unless @_lastLoading?
    @_lastLoading.find('.loading-screen').remove()
    @_lastLoading.find('>').removeClass('hidden')
    @_lastLoading = null

    
  #- Loading ModalViews

  enableModalInProgress: (modal) ->
    el = modal.find('.modal-content')
    el.find('> div', modal).hide()
    el.find('.wait', modal).show()

  disableModalInProgress: (modal) ->
    el = modal.find('.modal-content')
    el.find('> div', modal).show()
    el.find('.wait', modal).hide()

    
  #- Subscriptions

  addNewSubscription: BaseClass.prototype.addNewSubscription

  
  #- Shortcuts

  listenToShortcuts: (recurse) ->
    for shortcut, func of @shortcuts
      func = BaseClass.normalizeFunc(func, @)
      key(shortcut, @scope, _.bind(func, @))
    if recurse
      for viewID, view of @subviews
        view.listenToShortcuts()

  stopListeningToShortcuts: (recurse) ->
    key.deleteScope(@scope)
    if recurse
      for viewID, view of @subviews
        view.stopListeningToShortcuts()

        
  #- Subviews

  insertSubView: (view, elToReplace=null) ->
    # used to insert views with ids
    key = @makeSubViewKey(view)
    @subviews[key].destroy() if key of @subviews
    elToReplace ?= @$el.find('#'+view.id)
    elToReplace.after(view.el).remove()
    @registerSubView(view, key)
    view.render()
    view.afterInsert()
    view

  registerSubView: (view, key) ->
    # used to register views which are custom inserted into the view,
    # like views where you add multiple instances of them
    key = @makeSubViewKey(view)
    view.parent = @
    view.parentKey = key
    @subviews[key] = view
    view

  makeSubViewKey: (view) ->
    key = view.id or (view.constructor.name+classCount++)
    key = _.underscored(key)  # handy for autocomplete in dev console
    key

  removeSubView: (view) ->
    view.$el.empty()
    delete @subviews[view.parentKey]
    view.destroy()

    
  #- Utilities

  getQueryVariable: (param, defaultValue) -> BaseView.getQueryVariable(param, defaultValue)
  @getQueryVariable: (param, defaultValue) ->
    query = document.location.search.substring 1
    pairs = (pair.split('=') for pair in query.split '&')
    for pair in pairs when pair[0] is param
      return {'true': true, 'false': false}[pair[1]] ? decodeURIComponent(pair[1])
    defaultValue

  getRootView: ->
    view = @
    view = view.parent while view.parent?
    view

  
  #- Teardown

  destroy: ->
    @stopListening()
    @off()
    @stopListeningToShortcuts()
    @undelegateEvents() # removes both events and subs
    view.destroy() for id, view of @subviews
    $('#modal-wrapper .modal').off 'hidden.bs.modal', @modalClosed
    @[key] = undefined for key, value of @
    @destroyed = true
    @destroy = _.noop

