RootView = require 'views/kinds/RootView'
template = require 'templates/server-test-view'
requireUtils = require 'lib/requireUtils'
BaseCollection = require 'collections/BaseCollection'

TEST_URL_PREFIX = '/test/server/'

# TODO: deconstruct these class declarations so WebStorm can find them.

module.exports = ServerTestView = class ServerTestView extends RootView
  id: 'server-test-view'
  template: template
  
  events:
    'click .show-stack-button': 'onClickShowStackButton'

  constructor: (options, @subPath='') ->
    super(options)
    @specFiles = []
    @subPath = @subPath[1..] if @subPath[0] is '/'
    
    path = @subPath
    if path and not (_.string.endsWith(path, '/') or _.string.endsWith(path, 'coffee'))
      path = path + '/'

    # TODO: Have the tests run when you toggle a button, not immediately.
    jqxhr = $.post('/server-test/run', {path: path})
    jqxhr.done(_.bind(@onReportsLoaded, @))
    @supermodel.registerJQXHR(jqxhr)

    jqxhr = $.get('/server-test/list', {path: @subPath})
    jqxhr.done(_.bind(@onTestListLoaded, @))
    @supermodel.registerJQXHR(jqxhr)

    
  #- Report digestion. Tests were parsed from XML with odd names. Make the reports sensical.
    
  onReportsLoaded: (result) ->
    @stacks = []
    @rootDir = result.rootDir
    
    if result.consoleError
      @consoleError = @digestStack(result.consoleError)
      
    if result.reports
      suites = (obj.testsuites.testsuite for obj in result.reports)
      suites = _.flatten(suites)
      @suites = (@digestSuite(suite) for suite in suites)
    
  digestStack: (stack) ->
    short = []
    lastLineWasRemoved = false
    
    # shorten the stack by ...'ing all jasmine-node lines, and "removing" the rootDir.
    
    lineIsUseless = (line) ->
      return _.any([
          'node_modules/jasmine-node'
          'Timer.listOnTimeout'
          'process._tickCallback'
          'module.js'
        ], (substring) -> _.contains(line, substring)
      )
      
    for line, index in stack.split('\n')
      if lineIsUseless(line)
        continue if lastLineWasRemoved
        lastLineWasRemoved = true
        short.push '...'
        continue
      else
        lastLineWasRemoved = false
        index = line.indexOf(@rootDir)
        line = line[index+@rootDir.length...] if index > -1
        if _.contains(line, 'node_modules/')
          line = '|_・) /' + line
        else if index > 0
          line = '(/¯◡ ‿ ◡)/¯ ~ ~ ~ /' + line
        short.push(line)
        
    summary = short.shift()
        
    result = {
      summary: summary
      raw: stack
      short: short.join('</br>')
    }
    @stacks.push result
    return result
    
  digestSuite: (suite) ->
    nestings = suite.$.name.split('.')
    return {
      name: _.last(nestings)
      parents: _.first(nestings, nestings.length - 1)
      errors: parseInt(suite.$.errors)
      failures: parseInt(suite.$.failures)
      tests: (@digestTest(test) for test in suite.testcase)
      time: @digestTime(suite.$.time)
    }
    
  digestTime: (time) -> "#{(parseFloat(time)*1000).toFixed(0)} ms"
    
  digestTest: (test) ->
    result = {
      name: test.$.name
      time: @digestTime(test.$.time)
    }
    if test.failure
      result.failures = (@digestFailure(failure) for failure in test.failure)
    return result
    
  digestFailure: (failure) ->
    return {
      stack: @digestStack(failure._)
      type: failure.$.type # always expect? Is something broken?
      message: failure.$.message
    }

    
  #- other

  onClickShowStackButton: (e) ->
    $(e.target).closest('.panel-body').find('.hide').removeClass('hide')
    $(e.target).closest('.btn').hide()

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
    c.suites = @suites or []
    c.stacks = @stacks or []
    c
