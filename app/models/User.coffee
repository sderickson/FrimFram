BaseModel = require './BaseModel'

module.exports = class User extends BaseModel
  @className: 'User'
  @schema: 'http://my.site/schemas#user'
  urlRoot: '/db/user'