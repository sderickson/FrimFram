mongoose = require 'mongoose'
UserSchema = new mongoose.Schema({}, {strict: false, minimize: false})

User = mongoose.model('User', UserSchema)
User.schema = tv4.getSchema('http://my.site/schemas#user')

module.exports = User