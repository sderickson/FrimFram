# TODO: maybe move this into node_modules? I've heard of common modules going in there.

# TODO: list/enforce the properties details objects may have
#   - error: string version of the type of error
#   - code: the numeral code of the http response
#   - validationErrors: tv4 array of validation error objects
#   - message: string detailing what exactly went wrong
#   - property: string of the property that is erroneous, for the client to highlight, possibly

#- 200 responses
# http://en.wikipedia.org/wiki/List_of_HTTP_status_codes#2xx_Success

module.exports.ok = (res, data) ->
  send(res, 200, data)
  
module.exports.created = (res, data) ->
  send(res, 201, data)

module.exports.noContent = (res) ->
  res.sendStatus(204)


#- 400 client errors 
# http://en.wikipedia.org/wiki/List_of_HTTP_status_codes#4xx_Client_Error
  
module.exports.unauthorized = (res, details) ->
  # http://stackoverflow.com/questions/1748374/http-401-whats-an-appropriate-www-authenticate-header-value

  # Technically, this is an invalid response for 401. HTTP stipulates you need to
  # provide a WWW-Authenticate header which specifies something like "Basic"
  # or "Digest" authentication. But I need *some* code to indicate that the user
  # needs to login so I'm going to use this one. It's the closest one available.

  details = _.extend({ error: 'Unauthorized' }, details)
  send(res, 401, details)

module.exports.forbidden = (res, details) ->
  details = _.extend({ error: 'Forbidden' }, details)
  send(res, 403, details)

module.exports.notFound = (res, details) ->
  details = _.extend({ error: 'Not Found' }, details)
  send(res, 404, details)

module.exports.methodNotAllowed = (res, details) ->
  details = _.extend({ error: 'Method Not Allowed' }, details)
  send(res, 405, details)

module.exports.requestTimeout = (res, details) ->
  details = _.extend({ error: 'Request Timeout' }, details)
  send(res, 408, details)

module.exports.conflict = (res, details) ->
  details = _.extend({ error: 'Conflict' }, details)
  send(res, 409, details)

module.exports.unprocessableEntity = (res, details) ->
  # Use Unprocessable Entity 422 for when data is syntatically valid but semantically invalid.
  # http://www.bennadel.com/blog/2434-http-status-codes-for-invalid-data-400-vs-422.htm
  # http://stackoverflow.com/questions/9454811/which-http-status-code-to-use-for-required-parameters-not-provided
  details = _.extend({ error: 'Unprocessable Entity' }, details)
  if details.validationErrors
    details.validationErrors = (_.omit(error, 'stack') for error in details.validationErrors)
  send(res, 422, details)

  
#- 500 errors
# http://en.wikipedia.org/wiki/List_of_HTTP_status_codes#5xx_Server_Error
  
module.exports.internalServerError = (res, details) ->
  details = _.extend({ error: 'Internal Server Error' }, details)
  send(res, 500, details)

module.exports.gatewayTimeout = (res, details) ->
  details = _.extend({ error: 'Gateway Timeout' }, details)
  send(res, 504, details)


# All responses should return a JSON object with at least a code value.
send = (res, code, details) ->
  # TODO: JSON stringify any error objects passed in through err
  code ?= 500
  if code >= 400
    details.code = code or 500
  res.status(code).json(details)

  
