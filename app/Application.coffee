Router = require 'Router'

Application = FrimFram.Application.extend({
  router: new Router()

  initialize: ->
    @installSchema()
    @router.setupOnLeaveSite()

  #- Install the one root schema, all schemas can be referenced from it

  installSchema: ->
    @ajv = new ajv()
    modules = window.require.list()
    for module in modules.slice(_.sortedIndex(modules, 'schemas/'))
      if not _.startsWith(module, 'schemas/')
        break
      console.log 'add module', module.slice(8)
      @ajv.addSchema(require(module), module.slice(8))
})

module.exports = Application