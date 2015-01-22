authentication = require 'passport'
LocalStrategy = require('passport-local').Strategy
User = rootRequire 'server/models/User'
config = require '../../server_config'
respond = rootRequire 'server/respond'

module.exports.setup = (app) ->
  authentication.serializeUser (user, done) ->
    done(null, user._id)
  
  authentication.deserializeUser (id, done) ->
    User.findById id, (err, user) -> 
      done(err, user)

  authentication.use(new LocalStrategy(
    (username, password, done) ->

      q = { emailLower: username.toLowerCase() }

      User.findOne(q).exec((err, user) ->
        return done(err) if err
        return done(null, false, {message: 'Email not found.', property: 'email'}) if not user
        hash = User.hashPassword(password)
        unless user.get('passwordHash') is hash
          return done(null, false, {message: 'is wrong', property: 'password'})
        return done(null, user)
      )
  ))

  app.post('/auth/login', (req, res, next) ->
    authentication.authenticate('local', (err, user, info) ->
      return next(err) if err
      if not user
        return respond.unauthorized(res, [{message: info.message, property: info.property}])

      req.logIn user, (err) ->
        return next(err) if (err)
        activity = req.user.trackActivity 'login', 1
        user.update {activity: activity}, (err) ->
          return next(err) if (err)
          res.send(UserHandler.formatEntity(req, req.user))
          return res.end()
          
    )(req, res, next)
  )

  app.post('/auth/logout', (req, res) ->
    req.logout()
    res.end()
  )
