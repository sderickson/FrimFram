BaseModel = require './BaseModel'

module.exports = class User extends BaseModel
  @className: 'User'
  @schema: {}
  urlRoot: '/db/user'