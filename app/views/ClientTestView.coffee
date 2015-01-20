RootView = require 'views/kinds/RootView'
template = require 'templates/client-test-view'
requireUtils = require 'lib/requireUtils'

TEST_REQUIRE_PREFIX = 'test/app/'
TEST_URL_PREFIX = '/test/client/'

module.exports = ClientTestView = class ClientTestView extends RootView
  id: 'client-test-view'
  template: template
  reloadOnClose: true
  testingLibs: ['jasmine', 'jasmine-html', 'boot', 'mock-ajax', 'test-app']
  
  events:
    'click .reload-link': 'clearSpecParam' # not exactly sure why it needs this to navigate
  
  #- Initialization

  constructor: (options, @subPath='') ->
    super(options)
    @subPath = @subPath[1..] if @subPath[0] is '/'
    @loadTestingLibs()

  loadTestingLibs: ->
    return @scriptsLoaded() if @testingLibs.length is 0
    f = @testingLibs.shift()
    $.getScript("/javascripts/#{f}.js", => @loadTestingLibs())

  onFileLoad: (e) ->
    @loadedFileIDs.push e.item.id if e.item.id

  scriptsLoaded: ->
    @initSpecFiles()
    @render()
    ClientTestView.runTests(@specFiles)
    window.runJasmine()

    
  #- Rendering

  getContext: ->
    c = super(arguments...)
    c.parentFolders = requireUtils.getParentFolders(@subPath, TEST_URL_PREFIX)
    c.children = requireUtils.parseImmediateChildren(@specFiles, @subPath, TEST_REQUIRE_PREFIX, TEST_URL_PREFIX)
    parts = @subPath.split('/')
    c.currentFolder = parts[parts.length-1] or parts[parts.length-2] or 'All'
    c.lastParent = _.last(c.parentFolders)
    c.hasSpecFocus = document.location.href.indexOf('?') > -1
    c

    
  #- Running tests

  initSpecFiles: ->
    @specFiles = ClientTestView.getAllSpecFiles()
    if @subPath
      prefix = TEST_REQUIRE_PREFIX + @subPath
      @specFiles = (f for f in @specFiles when _(f).startsWith(prefix).value())
      
  @runTests: (specFiles) ->
    describe 'Client', ->
      specFiles ?= @getAllSpecFiles()
      jasmine.Ajax.install()
      beforeEach ->
        jasmine.Ajax.requests.reset()
        Backbone.Mediator.init()
        Backbone.Mediator.setValidationEnabled false
  
      require f for f in specFiles # runs the tests

  @getAllSpecFiles = ->
    allFiles = window.require.list()
    (f for f in allFiles when f.indexOf('.spec') > -1)

    
  #- Navigation

  clearSpecParam: ->
    document.location.href = document.location.pathname