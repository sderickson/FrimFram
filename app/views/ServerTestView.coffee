requireUtils = require 'lib/requireUtils'

TEST_URL_PREFIX = '/test/server/'

class ServerTestView extends FrimFram.RootView
  id: 'server-test-view'
  template: require 'templates/server-test-view'
  status: 'Off'

  events:
    'click .show-stack-button': 'onClickShowStackButton'
    'click #toggle': 'onToggleTesting'

  constructor: (options) ->
    super(options)
    @specFiles = []
    @subPath = options.params[0] or ''
    @subPath = @subPath[1..] if @subPath[0] is '/'

    $.ajax('/server-test/list', {
      success: _.bind(@onTestListLoaded, @)
      error: FrimFram.onAjaxError
    })

    $.ajax('/server-test/running', {
      success: _.bind(@onServerRunningLoaded, @)
      error: FrimFram.onAjaxError
    })

    @runTests = _.bind(_.debounce(@runTests, 200), @)

  onServerRunningLoaded: (testing) ->
    @setTesting(testing)
    if testing
      @listenForChanges()
    else
      @setStatus('Off')

  listenForChanges: ->
    @setStatus('Listening In')
    self = @
    @connection?.close()
    @connection = new WebSocket('ws://localhost:3002')
    @connection.onopen = -> self.runTests()
    @connection.onerror = (error) -> console.error 'web socket errored', error
    @connection.onmessage = (message) -> self.runTests()
    @connection.onclose = -> self.setupServerTesting() if self.testing

  runTests: ->
    @setStatus('Running Tests')
    path = @subPath
    if path and not (_(path).endsWith('/').value() or _(path).endsWith('coffee').value())
      path = path + '/'
    $.ajax('/server-test/run', {
      type: 'POST'
      data: {path: path}
      success: _.bind(@onReportsLoaded, @)
      error: FrimFram.onAjaxError
    })

  setupServerTesting: =>
    @setTesting(true)
    @setStatus('Initializing Testing System')
    $.ajax('/server-test/setup', {
      type: 'POST'
      success: _.bind(@listenForChanges, @)
      error: _.bind(@onServerTestingSetupFailed, @)
    })

  onServerTestingSetupFailed: ->
    @setStatus('Server Down, Polling...')
    setTimeout(@setupServerTesting, 3000)

  teardownServerTesting: ->
    @setTesting(false)
    @connection?.close()
    @setStatus('Restarting Server')
    $.ajax('/server-test/teardown', {
      type: 'POST'
      success: _.bind(@onTeardownDone, @)
      error: FrimFram.onAjaxError
    })

  onTeardownDone: ->
    @setStatus('Off')

  setStatus: (@status) ->
    @$el.find('#status').text(@status)

  onToggleTesting: ->
    if @testing then @teardownServerTesting() else @setupServerTesting()

  setTesting: (@testing) ->
    toggle = @$el.find('#toggle')
    toggle.removeClass('btn-danger btn-success')
    toggle.addClass(if @testing then 'btn-success' else 'btn-danger')
    toggle.text(if @testing then 'Turn Off Testing' else 'Turn On Testing')

  #- Report digestion. Tests were parsed from XML with odd names. Make the reports sensical.

  onReportsLoaded: (result) ->
    @setStatus('Standing By')
    @stacks = []
    @rootDir = result.rootDir

    if result.consoleError
      @consoleError = @digestStack(result.consoleError)

    if result.reports
      suites = (obj.testsuites.testsuite for obj in result.reports)
      suites = _.flatten(suites)
      @suites = (@digestSuite(suite) for suite in suites)

    @render()

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
    return {
    name: suite.$.name
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
    @specFiles = (f for f in files when _(f).endsWith('.coffee'))
    if @subPath
      @specFiles = (f for f in @specFiles when _(f).startsWith(@subPath))

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
    c.status = @status
    c

  onRender: ->
    @setTesting(@testing)

  destroy: ->
    @connection?.close()
    super()

module.exports = ServerTestView