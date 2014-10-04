CocoModel = require './CocoModel'

module.exports = class User extends CocoModel
  @className: 'User'
  @schema: {}
  urlRoot: '/db/user'