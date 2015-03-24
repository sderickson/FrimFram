Router = require 'Router'
rootSchema = require 'schemas/root.schema'

Application = FrimFram.Application.extend({
  router: new Router()

  initialize: ->
    @installSchema()

  #- Install the one root schema, all schemas can be referenced from it
  
  installSchema: ->
    tv4.addSchema rootSchema
})

module.exports = Application