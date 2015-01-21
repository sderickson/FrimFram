RootView = require 'views/kinds/RootView'
template = require 'templates/server-test-view'
requireUtils = require 'lib/requireUtils'
BaseCollection = require 'collections/BaseCollection'

TEST_URL_PREFIX = '/test/server/'

# TODO: deconstruct these class declarations so WebStorm can find them.

module.exports = ServerTestView = class ServerTestView extends RootView
  id: 'server-test-view'
  template: template

  constructor: (options, @subPath='') ->
    super(options)
    @specFiles = []
    @subPath = @subPath[1..] if @subPath[0] is '/'
    
    path = @subPath
    if not (_.string.endsWith(path, '/') or _.string.endsWith(path, 'coffee'))
      path = path + '/'

    # TODO: Have the tests run when you toggle a button, not immediately.
    jqxhr = $.post('/server-test/run', {path: path})
    jqxhr.done(_.bind(@onReportsLoaded, @))
    @supermodel.registerJQXHR(jqxhr)

    jqxhr = $.get('/server-test/list', {path: @subPath})
    jqxhr.done(_.bind(@onTestListLoaded, @))
    @supermodel.registerJQXHR(jqxhr)



  onReportsLoaded: (@reports) ->
    
  onTestListLoaded: (files) ->
    @specFiles = (f for f in files when _.string.endsWith(f, '.coffee'))
    if @subPath
      @specFiles = (f for f in @specFiles when _(f).startsWith(@subPath).value())


  getContext: ->
    c = super(arguments...)
    c.parentFolders = requireUtils.getParentFolders(@subPath, TEST_URL_PREFIX)
    c.children = requireUtils.parseImmediateChildren(@specFiles, @subPath, '', TEST_URL_PREFIX)
    parts = @subPath.split('/')
    c.currentFolder = parts[parts.length-1] or parts[parts.length-2] or 'All'
    c.lastParent = _.last(c.parentFolders)
    c.hasSpecFocus = document.location.href.indexOf('?') > -1
    c.reports = @reports
    c
