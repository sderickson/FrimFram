module.exports = {
  id: '#objectId'
  $schema: 'http://json-schema.org/draft-04/schema#'
  title: 'MongoDB ObjectID'
  
  type: ['string', 'object']
  minLength: 24
  maxLength: 24
  pattern: "^[a-f0-9]+$"
}