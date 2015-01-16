User = projRequire('server/models/User')
respond = projRequire('server/respond')
utils = projRequire('server/utils')

editableProperties = ['email', 'name']


#- get /db/user/:handle

module.exports.getByHandle = (req, res) ->
  handle = req.params.handle
  isForSelf = req.user and (req.user.id is handle or req.user.get('slug') is handle)
  if isForSelf
    return returnUser(req, res, null, req.user)
  utils.getByHandle(User, req.params.handle, returnUser(req, res))


#- put /db/user/:handle

module.exports.put = (req, res) ->
  user = req.user
  unless user
    return respond.unauthorized(res)
  if user.id isnt req.body._id
    return respond.forbidden(res, { message: "Cannot put any user but yourself!" })

  input = req.body ? {}
  input = _.pick(input, editableProperties...)
  clone = _.merge({}, user.toObject())
  combined = _.extend(clone, input)
  result = tv4.validateMultiple(combined, User.schema)
  if not result.valid
    return respond.unprocessableEntity(res, { validationErrors: result.errors })

  user.set(key, value) for key, value of merged
  user.save(returnUser(req, res))

  
#- patch /db/user/:handle
  
module.exports.patch = (req, res) ->
  user = req.user
  unless user
    return respond.unauthorized(res)
  if user.id isnt req.body._id
    return respond.forbidden(res, { message: "Cannot patch any user but yourself!" })

  input = req.body ? {}
  input = _.pick(req.body, editableProperties...)
  clone = _.merge({}, user.toObject())
  merged = _.merge(clone, input)
  result = tv4.validateMultiple(merged, User.schema)
  if not result.valid
    return respond.unprocessableEntity(res, { validationErrors: result.errors })

  user.set(key, value) for key, value of merged
  user.save(returnUser(req, res))
  

#- post /db/user

module.exports.post = (req, res) ->
  user = new User(input)

  input = req.body ? {}
  input = _.pick(input, editableProperties...)
  clone = _.merge({}, user.toObject())
  merged = _.merge(clone, input)
  result = tv4.validateMultiple(merged, User.schema)
  if not result.valid
    return respond.unprocessableEntity(res, { validationErrors: result.errors })

  user.set(key, value) for key, value of merged
  user.save(returnCreatedUser(res))

returnCreatedUser = _.curry (res, err, user) ->
  if err
    return respond.internalServerError(res, { err: err })
  respond.created(res, formatUser(user, user))
  
  
#- delete /db/user/:handle
    
module.exports.delete = (req, res) ->
  user = req.user
  unless user
    return respond.unauthorized(res)
  if user.id isnt req.body._id
    return respond.forbidden(res, { message: "Cannot delete any user but yourself!" })

  user.remove(returnNoContent(res))

returnNoContent = _.curry (res, err) ->
  if err
    return respond.internalServerError(res, { err: err })
  respond.noContent(res)

  
#- UTILS
  
returnUser = _.curry (req, res, err, user) ->
  if err
    return respond.internalServerError(res, { err: err })
  if not user
    return respond.notFound(res)
  respond.ok(res, formatUser(user, req.user))

formatUser = (user, loggedInUser) ->
  user = user.toObject()
  user = _.omit(user, 'passwordHash')
  user = _.omit(user, 'email', 'emailSlug' unless loggedInUser and loggedInUser.id is user.id)
  return user
