e = process.env

module.exports = config = {
  port: e.FRIMFRAM_NODE_PORT or 3000
  sslPort: e.FRIMFRAM_SSL_NODE_PORT or 3443
  salt: e.FRIMFRAM_SALT or 'pepper'
  cookie_secret: e.FRIMFRAM_COOKIE_SECRET or 'chips ahoy'

  mongo:
    port: e.FRIMFRAM_MONGO_PORT or 27017
    host: e.FRIMFRAM_MONGO_HOST or 'localhost'
    db: e.FRIMFRAM_MONGO_DATABASE_NAME or 'frimfram'
    username: e.FRIMFRAM_MONGO_USERNAME or ''
    password: e.FRIMFRAM_MONGO_PASSWORD or ''
}

config.isProduction = config.mongo.host isnt 'localhost'
config.runningTests = false # changed by the server tests if true

module.exports = config
